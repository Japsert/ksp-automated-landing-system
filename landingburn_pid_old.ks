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
printAt("waiting until vertical speed < 0...", 0, 0).
wait until ship:verticalspeed < 0.
printAt("                                   ", 0, 0).

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
    parameter _throttle.
    
    set s to ship:altitude.
    set verticalThrustModifier to cos(vectorangle(ship:up:forevector, ship:facing:forevector)).
    set FeSum to 0.
    
    for i in range(FE_SAMPLE_COUNT) {
        set altToCheck to i * s/(FE_SAMPLE_COUNT-1). // evenly spaced (including 0 and s)
        set FeSum to FeSum + ship:availableThrustAt(
            body:atm:altitudePressure(altToCheck)
        ) * _throttle * verticalThrustModifier.
    }
    return FeSum / FE_SAMPLE_COUNT.
}

function getMeanFeTime {
    parameter _throttle.
    parameter _time.
    parameter meanAcc.
    
    set _s0 to ship:altitude.
    set _v0 to ship:verticalspeed.
    set a to meanAcc.
    
    set verticalThrustModifier to cos(vectorangle(ship:up:forevector, ship:facing:forevector)).
    set FeSum to 0.
    
    printAt("_throttle=" + _throttle + ", _time=" + _time + ", meanAcc=" + meanAcc, 0, 6).
    printAt("verticalThrustModifier=" + verticalThrustModifier, 0, 8).
    set times to list().
    set altitudes to list().
    
    for i in range(FE_SAMPLE_COUNT) {
        set t to i * _time/(FE_SAMPLE_COUNT-1).
        times:add(t).
        set altToCheck to _s0 + _v0*t + 1/2*a*t^2.
        altitudes:add(altToCheck).
        set thrustAtAlt to ship:availableThrustAt(
            body:atm:altitudePressure(altToCheck)
        ) * _throttle * verticalThrustModifier.
        set FeSum to FeSum + thrustAtAlt.
        //printAt("i=" + i, 0, 22+i).
        //printAt("t=" + round(t, 2), 4, 22+i).
        //printAt("alt=" + round(altToCheck, 2), 12, 22 + i).
        //printAt("thrustAtAlt=" + round(thrustAtAlt, 2), 25, 22 + i).
    }
    //log times:join(",") + ";" + altitudes:join(",") to "0:/logs/fe.csv".
    return FeSum / FE_SAMPLE_COUNT.
}

function getMeanG {
    set s to ship:altitude.
    set gSum to 0.
    for i in range(G_SAMPLE_COUNT) {
        set altToCheck to i * s/(G_SAMPLE_COUNT-1). // evenly spaced (including 0 and s)
        set gAtAlt to body:mu / (body:radius + altToCheck)^2.
        set gSum to gSum + gAtAlt.
    }
    return gSum / G_SAMPLE_COUNT.
}

// Before we enter the main loop, we calculate the first estimate of the mean acceleration.
// We use this to obtain more accurate measurements of Fe and g, by taking into account
// that the ship will spend more time at lower altitudes.

set s0 to SHIP_BOUNDS:bottomaltradar.
set v0 to ship:verticalspeed.
set throttleDelayDistance to
    v0 * THROTTLE_DELAY_TICKS * 1/TICKS_PER_SECOND.

set meanFe to getMeanFe(BURN_THROTTLE). // engine will produce less thrust as we descend
set meanG to getMeanG().                // gravity will increase as we descend
set meanFz to meanG * ship:mass.        // TODO: estimate mass loss
set meanFres to meanFe - meanFz.        // TODO: estimate drag
set meanVAcc to meanFres / ship:mass.   // acceleration will decrease as we descend
// s = s0 + v0*t + 1/2*a*t^2
//   = s0 - v0^2 / (2*a)
set meanELA to s0 - (v0^2) / (2*meanVAcc).

// Print program variables for debugging
printAt("isBurnStarted:         " + isBurnStarted + " ", 0, 11).
printAt("altitude:              " + round(s0, 2) + "        ", 0, 12).
printAt("vertical speed:        " + round(v0, 2) + "        ", 0, 13).

printAt("ELA:                   " + round(meanELA, 2) + "  ", 0, 15).

set tickStartTime to time:seconds.
until ship:status = "landed" {
    // Print tick duration keep track of loop performance
    printAt("last tick took " 
        + round((time:seconds - tickStartTime) / (1/TICKS_PER_SECOND)) 
        + " ticks (" + round(time:seconds - tickStartTime, 2) + "s)      ",
        0, 35).
    set tickStartTime to time:seconds.
    
    set s0 to SHIP_BOUNDS:bottomaltradar.
    set v0 to ship:verticalspeed.
    
    // Now, calculate after how many seconds the velocity will be 0.
    set secondsToZeroV to -v0 / meanVAcc.
    
    if not isBurnStarted {
        set meanFe to getMeanFeTime(BURN_THROTTLE, secondsToZeroV, meanVAcc).
        set meanFeOld to getMeanFe(BURN_THROTTLE).
    } else {
        set meanFe to getMeanFeTime(throttle, secondsToZeroV, meanVAcc).
        set meanFeOld to getMeanFe(throttle).
    }
    set meanG to getMeanG().
    set meanFz to meanG * ship:mass.
    set meanFres to meanFe - meanFz.
    set meanFresOld to meanFeOld - meanFz.
    set meanVAcc to meanFres / ship:mass.
    set meanVAccOld to meanFresOld / ship:mass.
    set meanELA to s0 - (v0^2) / (2*meanVAcc).
    set meanELAOld to s0 - (v0^2) / (2*meanVAccOld).
    if not isBurnStarted
        set throttleDelayDistance to v0 * THROTTLE_DELAY_TICKS * 1/TICKS_PER_SECOND.
    
    // Print program variables for debugging
    printAt("isBurnStarted:         " + isBurnStarted + " ", 0, 11).
    printAt("altitude:              " + round(s0, 2) + "        ", 0, 12).
    printAt("vertical speed:        " + round(v0, 2) + "        ", 0, 13).
    
    printAt("ELA:                   " + round(meanELA, 2) + "  ", 0, 15).
    printAt("old ELA:               " + round(meanELAOld, 2) + "  ", 0, 19).
    
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
