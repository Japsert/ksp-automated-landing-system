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
set landingBurnThrottle to 0.5.

lock steering to up.

setStatus("Launching!").

// Launch the rocket
lock throttle to 1.0.
stage.

// Full throttle until we're a certain distance above the ground
when groundHeight > 10 then {
    // Cut off the engine
    lock throttle to 0.
    setStatus("Cut throttle, waiting for landing burn...").
    
    // F_engine: thrust of the engine during the landing burn, in kN
    lock Fe to ship:maxthrust * landingBurnThrottle.
    // F_gravity: force of gravity on the ship, in kN
    lock Fz to -9.81 * ship:mass.
    // F_resulting: the resulting force on the ship, in kN
    lock Fres to Fe + Fz.
    // The acceleration of the ship, in m/s^2
    lock acceleration to Fres / ship:mass.
    // Account for a delay between setting the throttle value and the acceleration actually changing
    // The time is equal to 3 ticks, or 0.06 seconds
    lock throttleDelayOffset to -verticalSpeed * 0.06.
    // Calculate the height at which the landing burn should start
    lock landingBurnHeight to (verticalSpeed^2) / (2 * acceleration) + throttleDelayOffset.

    when groundHeight < landingBurnHeight and verticalSpeed < 0 then {
        // Start the landing burn
        lock throttle to landingBurnThrottle.
        setStatus("Started landing burn").
        
        // Cut throttle 3 ticks before the vertical speed reaches 0
        lock throttleDelayOffset to -acceleration * 0.06.
        when verticalSpeed >= throttleDelayOffset then {
            // Stop the landing burn
            setStatus("Landing burn complete, cutting throttle").
            lock throttle to 0.
            
            // Check ship status to see if we landed successfully
            when ship:status = "LANDED" then {
                setStatus("Landed!").
            }
        }
        
    }
}

until false {
    // Here, we can print out some debug info
}
