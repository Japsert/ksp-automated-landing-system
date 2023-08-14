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
wait until altitude <= 80000 and verticalSpeed < 0.
lock steering to srfRetrograde.
// Wait until we hit the atmosphere
wait until altitude <= 70000 and verticalSpeed < 0.
clearScreen.

// Measure the drag force and atmospheric density each tick, and calculate
// Cd * A using those values.
until false {
        
    local prevVelocityTime is time:seconds.
    local prevVelH is ship:groundSpeed.
    local prevVelV is ship:verticalSpeed.

    wait 0.
    
    // Drag force
    // To calculate the drag force, we can calculate the expected velocity in
    // the current tick based on gravity (the only force acting on the vessel,
    // other than drag), and then take the difference between the expected
    // velocity and the actual velocity.
    
    // get velocity from previous tick: prevHVelocity/prevVVelocity
    // apply gravity to vertical velocity
    // horizontal velocity is a function of altitude due to the Coriolis effect
    local g is (body:mu)/(body:radius + ship:altitude)^2.
    local gravAcc is -g.
    local dTime is time:seconds - prevVelocityTime.
    local expectedVelH is getExpectedVelH(ship:altitude).
    local expectedVelV is prevVelV + gravAcc * dTime.
    // get velocity from current tick
    local currentVelH is ship:groundSpeed.
    local currentVelV is ship:verticalSpeed.
    // compare expected horizontal/vertical velocity with current
    local velDiffH is currentVelH - expectedVelH.
    local velDiffV is currentVelV - expectedVelV.
    // DEBUG: ratio between velDiffV/H, rough indicator of accuracy
    local velDiffRatio is velDiffV/(abs(velDiffH)+velDiffV).
    // calculate drag velocity using Pythagorean theorem
    local dragVel is choose -sqrt(velDiffH^2 + velDiffV^2)
        if velDiffV < 0 else sqrt(velDiffH^2 + velDiffV^2).
    // calculate drag acceleration: a = dv/dt
    local dragAcc is dragVel / dTime.
    // calculate drag force: F = ma
    local dragForce is dragAcc * ship:mass * 1000. // why *1000?
    
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
    if atmDensity = 0 or sqrVelocity = 0 {
        print(atmDensity + " " + sqrVelocity).
    }
    local CdA is (2 * dragForce)/(atmDensity * sqrVelocity).
    // TODO: simplify; remove sqrVelocity (from atmDensity as well)
    // and the factor of 2, so we end up with Cd * A = FD / Q ???
    
    // Print results for this tick
    printVariables(list(
        list("prev vel H", prevVelH, "m/s"),
        list("prev vel V", prevVelV, "m/s"),
        list("grav acc", gravAcc, "m/s²"),
        list("dTime", dTime, "s"),
        list("exp vel H", expectedVelH, "m/s"),
        list("exp vel V", expectedVelV, "m/s"),
        list("cur vel H", currentVelH, "m/s"),
        list("cur vel V", currentVelV, "m/s"),
        list("vel diff H", velDiffH, "m/s"),
        list("vel diff V", velDiffV, "m/s"),
        list("vel diff ratio", velDiffRatio*100, "%"),
        list("drag vel", dragVel, "m/s"),
        list("drag acc", dragAcc, "m/s²"),
        list("drag force", dragForce/1000, "kN"),
        list("atm. density", atmDensity, "kg/m³"),
        list("Cd * A", CdA, "m²")
    )).
}

function getExpectedVelH {
    local parameter alt_.
    local coeffs is lexicon(
        "x^2", -3.998339e-10,
        "x^1", 5.804223e-4,
        "x^0", -9.524015e-3
    ).
    return coeffs["x^2"] * alt_^2 + coeffs["x^1"] * alt_ + coeffs["x^0"].
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
