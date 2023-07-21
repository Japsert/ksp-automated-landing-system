clearScreen.
set BURN_THROTTLE to 0.8.
set SHIP_BOUNDS to ship:bounds.
set TICKS_PER_SECOND to 50.
set THROTTLE_DELAY_TICKS to 3.
set FE_SAMPLE_COUNT to 10.
set G_SAMPLE_COUNT to 3.
set DOLOG to false.
if DOLOG {
    set LOG_PATH to "0:/logs/" + ship:altitude + ".log".
    if exists(LOG_PATH) {
        deletePath(LOG_PATH).
        print("Deleted old log file.").
    }
    log "time,altitude,vertical speed,mean acceleration,Fe,meanFe,g,meanG,Fz,meanFz,Fres,meanFres,expectedLandingAlt,throttleOffset,throttle,isBurnStarted" to LOG_PATH.
}

// CONTROL

stage.
lock steering to up.
set isBurnStarted to false.
set meanELA to 0.

// Logging trigger
set doLog to false.
if DOLOG {
    when meanELA <= 5000 then {
        set doLog to true.
    }
}

set interpolatedELA to meanELA.
set throttleDelayDistance to 0.

set oldELA to meanELA.
set ticksPerUpdate to 0.
set dELA to 0.
set dELAPerTick to 0.
set ticksSinceUpdate to 0.
set canInterpolate to false.
when true then {
    set newELA to meanELA.
    
    if oldELA = newELA {
        // no new ELA value, interpolate
        set ticksSinceUpdate to ticksSinceUpdate + 1.
        if canInterpolate {
            set dELAPerTick to dELA / ticksPerUpdate.
            set interpolatedELA to oldELA - dELAPerTick * ticksSinceUpdate.
        }
    } else {
        // ELA value updated
        if not canInterpolate and dELA <> 0 {
            // newELA is now our second known value, so we know how much to change
            set canInterpolate to true.
        }
        set dELA to oldELA - newELA.
        set interpolatedELA to newELA.
        set ticksPerUpdate to ticksSinceUpdate.
        set ticksSinceUpdate to 0.
        set oldELA to newELA.
    }
    
    // Print interpolated ELA for debugging
    printAt("interpolated ELA:      " + round(interpolatedELA, 2) + "     ", 0, 16).
    // dELAPerTick is an estimate for the error
    printAt("dELAPerTick:           " + round(dELAPerTick, 2) + "     ", 0, 17).

    printAt("LHS:                   " + round(interpolatedELA + throttleDelayDistance, 2) + "     ", 0, 19).
    printAt("RHS:                   " + round(dELA + dELAPerTick/2, 2) + "     ", 0, 20).
    preserve.
}

// Setup start burn trigger (wait until we have an actual interpolated ELA)
when canInterpolate then {
    // Start the burn when the interpolated ELA is less than the throttle delay distance and nearest to an interval of dELAPerTick
    when interpolatedELA + throttleDelayDistance <= dELA + dELAPerTick/2 then {
        set isBurnStarted to true.
        lock throttle to 0.8.
            printAt("Burn started.", 0, 22).
            printAt("interpolated ELA:      " + round(interpolatedELA, 2) + "     ", 0, 23).
            printAt("throttleDelayDistance: " + round(throttleDelayDistance, 2) + "     ", 0, 24).
            printAt("dELA:                  " + round(dELA, 2) + "     ", 0, 25).
            printAt("dELAPerTick:           " + round(dELAPerTick, 2) + "     ", 0, 26).
            
            printAt("LHS:                   " + round(interpolatedELA + throttleDelayDistance, 2) + "     ", 0, 27).
            printAt("RHS:                   " + round(dELA + dELAPerTick/2, 2) + "     ", 0, 28).
            // difference between LHS and RHS is the error
            printAt("error:                 " + round(interpolatedELA + throttleDelayDistance - (dELA + dELAPerTick/2), 2) + "     ", 0, 29).
        }
}

function getMeanFe {
    parameter t. // throttle
    set s to ship:altitude.
    set zenith to vectorangle(ship:up:forevector, ship:facing:forevector).
    set verticalThrustModifier to cos(zenith).
    set FeSum to 0.
    for i in range(FE_SAMPLE_COUNT) {
        set altToCheck to i * s/(FE_SAMPLE_COUNT-1). // evenly spaced (including 0 and s)
        set FeSum to FeSum + ship:availableThrustAt(
            body:atm:altitudePressure(altToCheck)
        ) * t * verticalThrustModifier.
    }
    return FeSum / FE_SAMPLE_COUNT.
}

function getMeanG {
    set s to ship:altitude.
    // return average of ground level g and current g
    //return (body:mu / body:radius^2 + body:mu / (body:radius + s)^2) / 2.
    
    set s to ship:altitude.
    set gSum to 0.
    for i in range(G_SAMPLE_COUNT) {
        set altToCheck to i * s/(G_SAMPLE_COUNT-1). // evenly spaced (including 0 and s)
        set gAtAlt to body:mu / (body:radius + altToCheck)^2.
        set gSum to gSum + gAtAlt.
    }
    return gSum / G_SAMPLE_COUNT.
}

set tickStartTime to time:seconds.
until ship:status = "landed" {
    // Print tick duration keep track of loop performance
    printAt("last tick took " 
        + round((time:seconds - tickStartTime) / (1/TICKS_PER_SECOND)) 
        + " ticks (" + round(time:seconds - tickStartTime, 2) + "s)      ",
        0, 35).
    set tickStartTime to time:seconds.
    
    // Current position
    set s0 to SHIP_BOUNDS:bottomaltradar.
    // Current velocity
    set v0 to ship:verticalspeed.
    if not isBurnStarted {
        // Mean acceleration estimated for the duration of the burn
        set meanFe to getMeanFe(BURN_THROTTLE). // engine will produce less thrust as we descend
        set meanG to getMeanG().                // gravity will increase as we descend
        set meanFz to meanG * ship:mass.        // TODO: estimate mass loss
        set meanFres to meanFe - meanFz.        // TODO: estimate drag
        set meanVAcc to meanFres / ship:mass.   // acceleration will decrease as we descend
        // s = s0 + v0*t + 1/2*a*t^2
        //   = s0 - v0^2 / (2*a)
        set meanELA to s0 - (v0^2) / (2*meanVAcc).
        set throttleDelayDistance to
            v0 * THROTTLE_DELAY_TICKS * 1/TICKS_PER_SECOND.
    } else {
        // The same as the above, but Fe is based on current thrust,
        // and there is no throttle delay
        set meanFe to getMeanFe(throttle).
        set meanG to getMeanG().
        set meanFz to meanG * ship:mass.
        set meanFres to meanFe - meanFz.
        set meanVAcc to meanFres / ship:mass.
        set meanELA to s0 - (v0^2) / (2*meanVAcc).
    }
    
    // Print program variables for debugging
    printAt("isBurnStarted:         " + isBurnStarted + " ", 0, 11).
    printAt("altitude:              " + round(s0, 2) + "        ", 0, 12).
    printAt("vertical speed:        " + round(v0, 2) + "        ", 0, 13).
    
    printAt("ELA:                   " + round(meanELA, 2) + "  ", 0, 15).
    
    // Log variables for debugging
    if doLog {
        log time:seconds
            + "," + s0
            + "," + v0
            + "," + meanVAcc
            + "," + Fe
            + "," + meanFe
            + "," + g
            + "," + meanG
            + "," + Fz
            + "," + meanFz
            + "," + Fres
            + "," + meanFres
            + "," + meanELA
            + "," + throttleDelayDistance
            + "," + throttle
            + "," + isBurnStarted
        to LOG_PATH.
    }
    
    wait 0.
}

set doLog to false.



// DEBUGGING

//lock steering to up.
//wait 1.
//lock throttle to 1.
//when ship:altitude > 20000 then {
//    lock throttle to 0.
//}
//until false {
//    wait 0.
//}
