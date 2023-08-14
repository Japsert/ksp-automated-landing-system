clearscreen.

// CONSTANTS

set START_TIME to time:seconds.
set TICKS_PER_SECOND to 50.
// The throttle amount to use during the landing burn
set LANDING_BURN_THROTTLE to 0.8.
//set MAX_PID_OUTPUT to 1 - LANDING_BURN_THROTTLE.
//set MIN_PID_OUTPUT to -LANDING_BURN_THROTTLE.
set INIT_BURN_HEIGHT to 10000.
set K_P to 0.03.
set K_I to 0.00.
set K_D to 0.00.
set LOG_PATH to "0:/logs/" + K_P + "_" + K_I + "_" + K_D + "_" + INIT_BURN_HEIGHT + ".log".
if exists(LOG_PATH) {
    deletePath(LOG_PATH).
    print("Deleted old log file.").
}
log "time,throttle,pidOffset,expectedLandAltitude,realGroundAltitude,landingBurnAltitude,verticalSpeed,acceleration,Fres,shipMass,Fe,Fz,shipMaxThrust,g" to LOG_PATH.
set PID to pidLoop(
    K_P,          // Proportional gain
    K_I,          // Integral gain
    K_D           // Derivative gain
    //MIN_PID_OUTPUT, // Minimum output: -100% throttle
    //MAX_PID_OUTPUT  // Maximum output: 100% throttle
).
set TARGET_ALT to 0.
set PID:SETPOINT to TARGET_ALT.

// VARIABLES

set doLog to false.

// Distance to the ground
lock groundAltitude to alt:radar.
// Distance between the bottom of the ship and the ground
lock realGroundAltitude to ship:bounds:BOTTOMALTRADAR.
// Expected altitude at which the ship should stop
set expectedLandAltitude to 0.
set pidOffset to 0.

// F_engine: thrust of the engine during the landing burn, in kN
lock Fe to ship:maxthrust * LANDING_BURN_THROTTLE.
// F_gravity: force of gravity on the ship, in kN
lock g to body:mu / (body:radius + groundAltitude)^2.
lock Fz to g * ship:mass.
// F_resulting: the resulting force on the ship, in kN
lock Fres to Fe - Fz.
// The acceleration of the ship, in m/s^2
lock acceleration to Fres / ship:mass.
// Calculate the altitude at which the landing burn should start
lock landingBurnAltitude to ((verticalSpeed - g * 0.06)^2) / (2 * acceleration).

// CONTROL

lock steering to srfRetrograde.

// Look ahead 3 ticks to compensate for delay between throttle change and actual change in acceleration
//lock s0 to realGroundAltitude.
//lock v0 to verticalSpeed.
//lock t to 3 * 1/TICKS_PER_SECOND.
//lock a_c to g.
//lock futureRealGroundAltitude to s0 + v0 * t + 0.5 * a_c * t^2.

when realGroundAltitude - 1000 <= landingBurnAltitude then {
    set doLog to true.
}

when realGroundAltitude <= landingBurnAltitude and verticalSpeed <= 0 then {
    lock landingBurnAltitude to ((verticalSpeed + acceleration * 0.06)^2) / (2 * acceleration).
    lock expectedLandAltitude to -landingBurnAltitude + realGroundAltitude.
    lock pidOffset to PID:update(time:seconds, expectedLandAltitude).
    lock throttle to LANDING_BURN_THROTTLE + pidOffset.
    //set doLog to true.
    log "> START " + (time:seconds - START_TIME) to LOG_PATH.
    
    when verticalSpeed >= 0 then {
        lock throttle to 0.
        set doLog to false.
        log "> STOP " + (time:seconds - START_TIME) to LOG_PATH.
    }
}

until false {
    //printAt("Kp: " + round(PID:kp, 3), 0, 10).
    //printAt("Ki: " + round(PID:ki, 3), 0, 11).
    //printAt("Kd: " + round(PID:kd, 3), 0, 12).
    //printAt("g: " + round(g, 3) + ", acceleration: " + round(acceleration, 3) + " m/s^2   ", 0, 13).
    //printAt("Throttle: " + round(throttle, 3) + "    ", 0, 14).
    //printAt("Altitude: " + round(groundAltitude, 3) + " m (real: " + round(realGroundAltitude, 3) + " m)   ", 0, 15).
    //printAt("Landing burn start altitude: " + round(landingBurnAltitude, 3) + " m   ", 0, 16).
    //printAt("Expected landing altitude: " + round(expectedLandAltitude, 3) + " m   ", 0, 17).
    if doLog {
        log time:seconds - START_TIME
            + "," + throttle
            + "," + pidOffset
            + "," + expectedLandAltitude
            + "," + realGroundAltitude
            + "," + landingBurnAltitude
            + "," + verticalSpeed
            + "," + acceleration
            + "," + Fres
            + "," + ship:mass
            + "," + Fe
            + "," + Fz
            + "," + ship:maxThrust
            + "," + g
            to LOG_PATH.
    }
    wait 0.
}
