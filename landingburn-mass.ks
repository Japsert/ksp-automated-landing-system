clearscreen.

// This script will land a rocket on the ground, using the landing legs to absorb the impact.
// The rocket launches, accelerates for 10 meters, then cuts the throttle and waits for the
// landing burn, which should take its vertical speed to 0 at exactly ground level.

// Get current distance to the ground, starting from the lowest point of the ship
local bounds_box is ship:bounds.
lock groundHeight to bounds_box:BOTTOMALTRADAR.
// Prints a new status message
function setStatus {
    parameter shipStatus.
    
    printAt("                                              ", 0, 10).
    printAt(shipStatus, 0, 10).
}
// The throttle amount to use during the landing burn
set landingBurnThrottle to 1.
set approximations to list(0, 0, 0, 0, 0, 0, 0, 0, 0, 0).

lock steering to up.

setStatus("Launching!").

// Launch the rocket
lock throttle to 1.
stage.

set landingBurnHeight to 0.
function calculateLandingBurnHeight {
    set Fe to ship:maxthrust * landingBurnThrottle.
    set Fz to constant:g0 * ship:mass.
    set Fres to Fe + Fz.
    set a_res to Fres / ship:mass.
    
    set m_start to ship:mass.
    
    from {local i is 0.} until i = 10 step {set i to i + 1.} do {
        set approximations[i] to a_res.
        set t to verticalSpeed / a_res.
        set maxMassFlow to ship:engines[0]:maxMassFlow.
        set deltaM to maxMassFlow * t.
        set m_avg to ship:mass - deltaM / 2.
        set Fz_avg to -constant:g0 * m_avg.
        set a_res_avg to (Fe + Fz_avg) / m_avg.
        set a_res to a_res_avg.
    }
    
    // here, a_res is the final average acceleration
    set throttleDelayOffset to -verticalSpeed * 0.06.
    set landingBurnHeight to (verticalSpeed^2) / (2 * a_res) + throttleDelayOffset.
    return landingBurnHeight.
}

// Full throttle until we're a certain distance above the ground
when groundHeight >= 1000 then {
    // Cut off the engine
    lock throttle to 0.
    setStatus("Cut throttle, waiting for landing burn...").
    
    until groundHeight <= landingBurnHeight and verticalSpeed < 0 {
        set landingBurnHeight to calculateLandingBurnHeight().
    }

    // Start the landing burn
    lock throttle to landingBurnThrottle.
    setStatus("Started landing burn").
    
    // Cut throttle 3 ticks before the vertical speed reaches 0
    lock m_end to m_start - deltaM.
    lock Fz_end to -constant:g0 * m_end.
    lock a_res_end to (Fe + Fz_end) / m_end.
    lock throttleDelayOffset to -a_res_end * 0.06.
    when verticalSpeed >= throttleDelayOffset then {
        // Stop the landing burn
        setStatus("Landing burn complete, cutting throttle").
        lock throttle to 0.
        
        when verticalSpeed >= 0 then {
            print "groundHeight: " + groundHeight.
        }
        
        // Check ship status to see if we landed successfully
        when ship:status = "LANDED" then {
            setStatus("Landed!").
        }
    }
}

until false {
    // Here, we can print out some debug info
    printAt("max mass flow: " + ship:engines[0]:maxMassFlow, 0, 11).
    from {local i is 0.} until i = approximations:LENGTH step {set i to i + 1.} do {
        printAt("approximation " + i + ": " + approximations[i], 0, 12 + i).
    }
    printAt("landing burn height: " + landingBurnHeight, 0, 25).
}
