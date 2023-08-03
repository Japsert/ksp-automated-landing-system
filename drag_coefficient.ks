@lazyGlobal off.
clearScreen.

global AP is 100000.

print("Launching to " + AP/1000 + " km. Have you turned on infinite fuel?").
// Launch to AP 100km
lock steering to up.
stage.
lock throttle to 1.
wait until apoapsis >= AP.
lock throttle to 0.
clearScreen.
print("AP reached " + AP + ", waiting until we hit the atmosphere.").
// Wait until we hit the atmosphere
wait until altitude <= 70000 and verticalSpeed < 0.
clearScreen.

// Measure the drag force and atmospheric density each tick, and calculate
// Cd * A using those values.

until false {
    
    // Drag force
    // To calculate the drag force, we can calculate the expected velocity in
    // the current tick based on gravity (the only force acting on the vessel,
    // other than drag), and then take the difference between the expected
    // velocity and the actual velocity.
    
    // get velocity from previous tick
    // apply gravity to vertical velocity
    // calculate expected velocity
    // compare expected velocity with velocity in current tick
    // calculate drag acceleration
    // calculate drag force
    local FD is 0.
    
    // Atmospheric density
    // To calculate the atmospheric density, we can use the method of dynamic
    // pressure and surface velocity (because we can assume that the dynamic
    // pressure reading is accurate enough that the atmospheric density is
    // accurate enough).
    
    local dynamicPressure is ship:q * constant:atmtokpa * 1000. // in Pa
    local sqrVelocity is ship:velocity:surface:sqrmagnitude.
    local atmDensity is (2 * dynamicPressure) / sqrVelocity.
    
    // Cd * A
    // We can calculate Cd * A by rewriting the drag equation into
    // Cd * A = (2*FD)/(ρ*v²).
    
    // TODO: this will result in NaN being pushed onto the stack
    // (likely) due to either atmDensity or sqrVelocity being 0.
    local CdA is (2 * FD)/(atmDensity * sqrVelocity).
    // TODO: simplify; remove sqrVelocity (from atmDensity as well)
    // and the factor of 2, so we end up with Cd * A = FD / Q ???
    
    // Print results for this tick
    printVariables(list(
        list("atm. density", atmDensity, "kg/m³"),
        list("Cd * A", CdA, "m²")
    )).
    
    wait 0.
}

function printVariables {
    local parameter vars. // list of lists
    
    local maxVarLength is 0.
    for var in vars {
        local varName is var[0].
        set maxVarLength to max(maxVarLength, varName:length).
    }
    
    from {local i is 0.} until i = vars:length step {set i to i + 1.} do {
        local var is vars[i].
        local varName is var[0].
        local varValue is var[1].
        local varUnit is var[2].
        printLn(
            (varName + ": "):padright(maxVarLength + 2)
            + varValue + " " + varUnit, i
        ).
    }
}

function printLn {
    local parameter string.
    local parameter line.
    
    set string to string:padright(terminal:width).
    printAt(string, 0, line).
}
