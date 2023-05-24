clearscreen.

lock steering to up.
stage.
set startTime to time:seconds.

set pid to pidLoop(
    0.3, // Proportional gain
    0.3, // Integral gain
    0.3, // Derivative gain
    0,    // Minimum output: 0% throttle
    1     // Maximum output: 100% throttle
).
set targetAlt to 20.
set pid:setpoint to targetAlt.

set wanted_throttle to 0.
lock throttle to wanted_throttle.

lock groundAltitude to alt:radar.

until time:seconds > startTime + 10 {
    set wanted_throttle to pid:update(time:seconds, groundAltitude).
    printAt("Kp: " + round(pid:kp,3), 0, 10).
    printAt("Ki: " + round(pid:ki,3), 0, 11).
    printAt("Kd: " + round(pid:kd,3), 0, 12).
    printAt("PID throttle: " + round(wanted_throttle,3) + "    ", 0, 13).
    printAt("Altitude: " + round(groundAltitude,3), 0, 14).
    log time:seconds - startTime + " " + groundAltitude + " " + wanted_throttle to log.
    wait 0.
}

copyPath("log", "0:/").
