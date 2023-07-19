clearScreen.
set BURN_THROTTLE to 0.8.
set SHIP_BOUNDS to ship:bounds.
set TICKS_PER_SECOND to 50.
set THROTTLE_DELAY_TICKS to 3.
set SAMPLE_COUNT to 5.

// CONTROL

stage.
lock steering to up.
set isBurnStarted to false.
set expectedLandingAlt to 1. // > 0 to not trigger the when condition below
set throttleDelayDistance to 0.
when expectedLandingAlt + throttleDelayDistance <= 0 then {
    set isBurnStarted to true.
    lock throttle to 0.8.
}

function getMeanFe {
    parameter t. // throttle
    set s to ship:altitude.
    set FeSum to 0.
    for i in range(SAMPLE_COUNT) {
        set altToCheck to i * s/(SAMPLE_COUNT-1). // evenly spaced (including 0 and s)
        set FeSum to FeSum + ship:availableThrustAt(
            body:atm:altitudePressure(altToCheck)
        ) * t.
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
        set meanAcc to meanFres / ship:mass.    // acceleration will decrease as we descend
        // s = s0 + v0*t + 1/2*a*t^2
        //   = s0 - v0^2 / (2*a)
        set expectedLandingAlt to s0 - v0^2 / (2*meanAcc).
        set throttleDelayDistance to
            v0 * THROTTLE_DELAY_TICKS * 1/TICKS_PER_SECOND.
    } else {
        // The same as the above, but Fe is based on current thrust,
        // and there is no throttle delay
        set meanFe to getMeanFe(throttle).
        set meanG to getMeanG().
        set meanFz to meanG * ship:mass.
        set meanFres to meanFe - meanFz.
        set meanAcc to meanFres / ship:mass.
        set expectedLandingAlt to s0 - v0^2 / (2*meanAcc).
    }
    
    // Print isBurnStarted, s0, v0, a, expectedLandingAlt, throttleOffset
    printAt("isBurnStarted:      " + isBurnStarted + " ", 0, 11).
    printAt("altitude:           " + round(s0, 2), 0, 12).
    printAt("vertical speed:     " + round(v0, 2), 0, 13).
    printAt("mean acceleration:  " + round(meanAcc, 2), 0, 14).
    
    printAt("meanFe:             " + round(meanFe, 2), 0, 16).
    printAt("meanG:              " + round(meanG, 2), 0, 17).
    printAt("meanFz:             " + round(meanFz, 2), 0, 18).
    printAt("meanFres:           " + round(meanFres, 2), 0, 19).
    
    printAt("expectedLandingAlt: " + round(expectedLandingAlt, 2), 0, 21).
    printAt("throttleOffset:     " + round(throttleDelayDistance, 2), 0, 22).
    
    wait 0.
}



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
