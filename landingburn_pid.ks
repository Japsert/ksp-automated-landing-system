clearScreen.
set BURN_THROTTLE to 0.8.
set SHIP_BOUNDS to ship:bounds.
set TICKS_PER_SECOND to 50.
set THROTTLE_DELAY_TICKS to 3.
set SAMPLE_COUNT to 5.
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
set meanELA to 5001. // > 0 to not trigger the when condition below
set throttleDelayDistance to 0.
when meanELA + throttleDelayDistance <= 0 then {
    set isBurnStarted to true.
    lock throttle to 0.8.
}
set doLog to false.
when meanELA <= 5000 then {
    if DOLOG set doLog to true.
}

set realVerticalAcc to 0.0.
set lastTime to time:seconds.
set lastVerticalSpeed to verticalSpeed.
when true then {
    set dt to time:seconds - lastTime.
    set realVerticalAcc to (verticalSpeed - lastVerticalSpeed) * 1/dt.
    set lastTime to time:seconds.
    set lastVerticalSpeed to verticalSpeed.
    preserve.
}

function getMeanFe {
    parameter t. // throttle
    set s to ship:altitude.
    set facingVector to facing:vector.
    set FeSum to 0.
    for i in range(SAMPLE_COUNT) {
        set altToCheck to i * s/(SAMPLE_COUNT-1). // evenly spaced (including 0 and s)
        set FeSum to FeSum + ship:availableThrustAt(
            body:atm:altitudePressure(altToCheck)
        ) * t * facingVector:z.
    }
    return FeSum / SAMPLE_COUNT.
}

function getMeanG {
    set s to ship:altitude.
    // return average of ground level g and current g
    return (body:mu / body:radius^2 + body:mu / (body:radius + s)^2) / 2.
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
        set meanVAcc to meanFres / ship:mass.    // acceleration will decrease as we descend
        // s = s0 + v0*t + 1/2*a*t^2
        //   = s0 - v0^2 / (2*a)
        set meanELA to s0 - v0^2 / (2*meanVAcc).
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
        set meanELA to s0 - v0^2 / (2*meanVAcc).
    }
    
    // Print program variables for debugging
    printAt("isBurnStarted:      " + isBurnStarted + " ", 0, 11).
    printAt("altitude:           " + round(s0, 2) + "        ", 0, 12).
    printAt("vertical speed:     " + round(v0, 2) + "        ", 0, 13).
    
    set Fe to ship:availableThrust * BURN_THROTTLE.
    printAt("Fe / meanFe:        " + round(Fe, 2)   + " / " + round(meanFe, 2)   + "        ", 0, 15).
    set g to body:mu / (body:radius + ship:altitude)^2.
    printAt("g / meanG:          " + round(g, 2)    + " / " + round(meanG, 2)    + "        ", 0, 16).
    set Fz to g * ship:mass.
    printAt("Fz / meanFz:        " + round(Fz, 2)   + " / " + round(meanFz, 2)   + "        ", 0, 17).
    set Fres to Fe - Fz.
    printAt("Fres / meanFres:    " + round(Fres, 2) + " / " + round(meanFres, 2) + ", real: " + round(ship:mass * realVerticalAcc, 2) + "        ", 0, 18).
    
    set vAcc to Fres / ship:mass.
    printAt("vAcc / meanVAcc:    " + round(vAcc, 2)  + " / " + round(meanVAcc, 2)  + ", real: " + round(realVerticalAcc, 2) + "        ", 0, 19).
    
    set ELA to s0 - v0^2 / (2*vAcc).
    printAt("ELA / meanELA:      " + round(ELA, 2)  + " / " + round(meanELA, 2)  + "        ", 0, 21).
    printAt("throttleOffset:     " + round(throttleDelayDistance, 2) + "        ", 0, 22).
    
    // print real Fres and current calculated Fres
    printAt("these need to be equal:", 0, 24).
    printAt("- real Fres:    " + round(ship:mass * realVerticalAcc, 2) + "        ", 0, 25).
    printAt("- current Fres: " + round(ship:thrust - Fz, 2) + "        ", 0, 26).
    // print real vAcc and current calculated vAcc
    printAt("and these:", 0, 27).
    printAt("- real vAcc:    " + round(realVerticalAcc, 2) + "        ", 0, 28).
    printAt("- current vAcc: " + round((ship:thrust - Fz) / ship:mass, 2) + "        ", 0, 29).
    
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
