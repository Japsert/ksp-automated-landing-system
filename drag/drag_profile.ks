// Script that helps with building a lookup table for Cd*A as a function of
// Mach number.
local parameter MACH_TO_TEST is 0.100. // Mach number to test at

global SPEED_OF_SOUND is 330.
global GRAV_ACC is -9.7.

// TODO: speed of sound and gravity aren't constant
local currentAlt is ship:altitude.
local altitudeToLaunchTo is currentAlt + -(MACH_TO_TEST * SPEED_OF_SOUND)^2 / (2 * GRAV_ACC).

lock steering to heading(90, 90).
stage.
lock throttle to 1.

print("Waiting for apoapsis to reach " + round(altitudeToLaunchTo) + " m...").
wait until ship:apoapsis >= altitudeToLaunchTo.
lock throttle to 0.

print("Done! And now, we crash :)").

wait until ship:verticalspeed < -5.
lock steering to srfRetrograde.

wait until false.
