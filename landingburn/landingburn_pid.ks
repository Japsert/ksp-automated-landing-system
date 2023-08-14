clearScreen.
stage.
lock steering to up.
lock throttle to 0.

set INITIAL_BURN_AP to 5000.

if ship:status = "prelaunch" or ship:status = "landed" {
    printAt("Burning until apoapsis >= " + INITIAL_BURN_AP + ".", 0, 0).
    printAt("Press any key to interrupt.", 0, 1).
    lock throttle to 1.
    wait until terminal:input:haschar or ship:apoapsis >= INITIAL_BURN_AP.
    clearScreen.
    lock throttle to 0.
}


////////////////////////////////////////////////////////////////////////////////
// Constants
////////////////////////////////////////////////////////////////////////////////

set START_TIME to time:seconds.            // Time at which the script started
set LOG_PATH to "0:/logs/landingburn.log". // Path to log file
if exists(LOG_PATH) deletePath(LOG_PATH).  // Delete log file if it exists
set TERMINAL_LOGS to 0.
set TERMINAL_VARS to 10.
set numberOfVars to 0.
lock TERMINAL_OTHER to TERMINAL_VARS + numberOfVars + 2.
set TERMINAL_LAST TO terminal:height - 1.
set SHIP_BOUNDS to ship:bounds.
set BURN_THROTTLE to 1.      // Throttle to use during landing burn
set THROTTLE_DELAY_TICKS to 3. // Number of ticks between setting throttle and
                               // the acceleration changing
set TICKS_PER_SECOND to 50.    // Number of ticks per second
set PID to pidLoop(            // PID controller to control throttle
    0.03,  // Kp
    0.0,  // Ki
    0.0   // Kd
).
//set interpBurnAltitude to 0.     // Interpolated burn altitude
set PID:setpoint to 0.           // PID setpoint


////////////////////////////////////////////////////////////////////////////////
// Variables
////////////////////////////////////////////////////////////////////////////////

set wroteHeader to false.
set isBurnStarted to false.      // Whether the landing burn has started
set burnAltitude to 0.           // Altitude at which to start the landing burn
lock groundAltitude to SHIP_BOUNDS:bottomaltradar. // Real altitude
set v0 to ship:verticalspeed.


////////////////////////////////////////////////////////////////////////////////
// Triggers
////////////////////////////////////////////////////////////////////////////////


// Trigger that prints the vertical speed when we hit the ground,
// for debugging purposes.
when groundAltitude < 1 then {
    printAt("vertical speed: " + round(ship:verticalspeed, 2), 0, TERMINAL_OTHER + 2).
}

// Trigger that updates the observed vertical acceleration.
set lastV to ship:verticalspeed.
set ticksSkipped to 0.
when true then {
    set ticksSkipped to ticksSkipped + 1.
    if ticksSkipped = 2 {
        set vAcc to (ship:verticalspeed - lastV) * TICKS_PER_SECOND / ticksSkipped.
        set lastV to ship:verticalspeed.
        set ticksSkipped to 0.
        printAt("observed vAcc: " + round(vAcc, 2) + "    ", 0, TERMINAL_OTHER + 1).
    }
    preserve.
}


// Register trigger to initiate the landing burn at the correct altitude.
// The trigger takes into account:
// - the three-tick delay between the throttle being set
//   and the acceleration changing 
// - the interpolation between the current and previous burn altitude
// - that the interpolated burn altitude is from the previous tick
// - that the ship altitude can be slightly above the burn altitude,
//   so we should check in a range of dAlt around the burn altitude
lock throttleDelayDistance to v0 * THROTTLE_DELAY_TICKS * 1/TICKS_PER_SECOND.
//set canInterpolate to false.
//when canInterpolate then {
    when ship:verticalspeed < 0 and ship:status = "flying"
        and groundAltitude + throttleDelayDistance <= burnAltitude then {
        set isBurnStarted to true.
        //lock pidOffset to
        //    PID:update(time:seconds, groundAltitude - interpBurnAltitude).
        //lock throttle to BURN_THROTTLE + pidOffset.
        lock throttle to BURN_THROTTLE.
        local error is groundAltitude - burnAltitude.
        printAt("burn started. error: " + error, 0, 0).
    }
//}


// Interpolation trigger. Runs every tick and interpolates between the current
// and previous burn altitude to determine the tick at which to start the burn.
set oldAlt to burnAltitude.
set ticksPerUpdate to 0.
set dAlt to 0.
set dAltPerTick to 0.
set ticksSinceUpdate to 0.
set diff to 0. // temp
when true then {
    set newAlt to burnAltitude.
    
    if oldAlt = newAlt {
        // no new burn alt value, interpolate
        set ticksSinceUpdate to ticksSinceUpdate + 1.
        if canInterpolate {
            set dAltPerTick to
                choose dAlt / ticksPerUpdate
                if ticksPerUpdate <> 0
                else 0.
            set interpBurnAltitude to oldAlt - dAltPerTick * ticksSinceUpdate.
        }
    } else {
        // burn alt value updated
        if not canInterpolate and dAlt <> 0 {
            // newAlt is now our second known value,
            // so we know how much to interpolate by
            set canInterpolate to true.
        }
        set dAlt to oldAlt - newAlt.
        set interpBurnAltitude to newAlt.
        set ticksPerUpdate to ticksSinceUpdate.
        set ticksSinceUpdate to 0.
        set oldAlt to newAlt.
    }
    
    // Override groundAltitude and interpBurnAltitude printed in the main loop.
    printAt("altitude:             " + round(groundAltitude, 2), 0, TERMINAL_VARS).
    printAt("interp burn altitude: " + round(interpBurnAltitude, 2), 0, TERMINAL_VARS + 2).
    printAt("diff: " + round(diff, 3), 0, TERMINAL_OTHER).
    
    //logVariables(lexicon(
    //    "altitude", groundAltitude,
    //    "burn altitude", burnAltitude,
    //    "interp burn altitude", interpBurnAltitude
    //)).
    
    preserve.
}


////////////////////////////////////////////////////////////////////////////////
// Main loop
////////////////////////////////////////////////////////////////////////////////
set tickStartTime to time:seconds.
until (isBurnStarted and ship:verticalspeed >= 0) or ship:status = "landed" {
    // Print tick duration keep track of loop performance
    printAt("last tick took " 
        + round((time:seconds - tickStartTime) / (1/TICKS_PER_SECOND)) 
        + " ticks (" + round(time:seconds - tickStartTime, 2) + "s)      ",
        0, TERMINAL_LAST).
    set tickStartTime to time:seconds.

    //if not isBurnStarted {
        // The free-fall phase. We repeatedly calculate the altitude at
        // which to start the landing burn.
        set burnAltitude to calculateBurnAltitude().
        
        printVariables(lexicon(
            "altitude", groundAltitude,
            "burn altitude", burnAltitude,
            //"interp burn altitude", interpBurnAltitude,
            "s0", s0,
            "v0", v0,
            "ag", ag,
            "ab", ab,
            "tburn", tburn,
            "sburn", sburn
        )).
        
        logVariables(lexicon(
            "altitude", groundAltitude,
            "burn altitude", burnAltitude
            //"interp burn altitude", interpBurnAltitude
        )).
    //} else {
    //    // The landing burn phase. We repeatedly calculate the expected
    //    // landing altitude, and adjust the throttle with a PID controller.
    //    set burnAltitude to calculateExpectedLandingAltitude().
        
    //    printVariables(lexicon(
    //        "altitude", groundAltitude,
    //        "burn altitude", burnAltitude,
    //        "interp burn altitude", interpBurnAltitude,
    //        "s0", s0,
    //        "v0", v0,
    //        "ag", ag,
    //        "Fe", Fe,
    //        "ab", ab,
    //        "ELA", expectedLandingAltitude
    //    )).
    //}
}

lock throttle to 0.


////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////

// Calculates the altitude at which to start the landing burn.
// The following effects are taken into account:
// - Engine output decreases at lower altitudes
// - Gravity increases at lower altitudes
// The following effects are not yet taken into account:
// - Atmospheric drag
// - Mass lowers as fuel is burned
function calculateBurnAltitude {
    set s0 to groundAltitude.
    set v0 to ship:verticalspeed.
    set ag to -(body:mu / (body:radius)^2). // TODO: make function of altitude
    set Fe to ship:availablethrust * BURN_THROTTLE.
    set ab to (Fe / ship:mass) + ag.
    set abcA to (ag*ab - ag^2)/(2*ab).
    set abcB to v0 - ag/ab * v0.
    set abcC to s0 - v0^2/(2*ab).
    set abcD to max(abcB^2 - 4*abcA*abcC, 0).
    set tburn to (-abcB - sqrt(abcD))/(2*abcA).
    set sburn to s0 + v0*tburn + 1/2*ag*tburn^2.
    return sburn.
}


// Calculates the expected landing altitude.
// TODO: maybe use this instead of the function above, because it's faster?
function calculateExpectedLandingAltitude {
    set s0 to groundAltitude.
    set v0 to ship:verticalspeed.
    set ag to -(body:mu / (body:radius)^2). // TODO: make function of altitude
    set Fe to ship:availablethrust * BURN_THROTTLE.
    set ab to (Fe / ship:mass) + ag.
    set expectedLandingAltitude to s0 - v0^2/(2*ab).
    return expectedLandingAltitude.
}


// Prints the given variables to the output terminal.
// vars: Lexicon of variables to print, consisting of variable name and value.
function printVariables {
    parameter vars. // Lexicon of variables to print
    
    set numberOfVars to vars:length.
    
    // Determine the length of the longest variable name.
    set maxVarLength to 0.
    for var in vars:keys {
        set varLength to var:tostring:length.
        if varLength > maxVarLength {
            set maxVarLength to varLength.
        }
    }
    
    from {local i is 0.} until i = vars:length step {set i to i + 1.} do {
        set varName to vars:keys[i].
        set var to vars[varName].
        printAt(
            (varName + ": "):padright(maxVarLength + 2)
            + (choose round(var, 2) if var:istype("Scalar") else var) + "    ",
            0, TERMINAL_VARS + i
        ).
    }
}


// Logs the given variables to the log file.
// vars: Lexicon of variables to log, consisting of variable name and value.
function logVariables {
    parameter vars. // Lexicon of variables to log
    if not wroteHeader {
        log ("time," + vars:keys:join(",")) to LOG_PATH.
        set wroteHeader to true.
    }
    log (time:seconds - START_TIME) + "," + vars:values:join(",") to LOG_PATH.
}
