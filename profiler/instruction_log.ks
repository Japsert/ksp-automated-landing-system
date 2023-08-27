// A reference for how many instructions a given code block takes, and other
// info useful for performance optimization.

// 9
vecDraw(pos, vec, red, "", 1, true).

// 6
body:geopositionOf(vec).

// 6
body:altitudeOf(vec).

// Accessing a suffix takes 1 instruction.
// 2
mass.
// 3
ship:mass.

// Creating a variable costs the same as setting one.
// 2
local x is 0.
// 3
set x to 0.

// Even if you don't store the result in a variable, the CPU will still store it
// somewhere.
// 2
local a is altitude.
// 2
altitude.

// Storing a value in a variable takes 1 instruction.
