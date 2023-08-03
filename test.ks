clearScreen.

until false {
    set staticPressure to ship:sensors:pres * 1000.
    set temp to ship:body:atm:altitudetemperature(ship:altitude) + 21.
    set molarMass to body:atm:molarmass.
    set atmDensity to (staticPressure * molarMass) / (constant:idealGas * temp).
    set dynamicPressure to ship:q * constant:atmtokpa * 1000.
    set sqrVelocity to ship:velocity:surface:sqrmagnitude.
    set atmDensity2 to (2 * dynamicPressure) / sqrVelocity.
    printVariables(list(
        list("staticPressure", staticPressure, "Pa"),
        list("temp", temp, "K"),
        list("molarMass", molarMass, "kg/mol"),
        list("atmDensity", atmDensity, "kg/m³"),
        list("", "", ""),
        list("dynamicPressure", dynamicPressure, "Pa"),
        list("sqrVelocity", sqrVelocity, "(m/s)²"),
        list("atmDensity2", atmDensity2, "kg/m³")
    )).
    
    wait 0.
}

function printVariables {
    local parameter vars. // list of lists
    
    // Determine the length of the longest variable name.
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
        printAt(
            (varName + ": "):padright(maxVarLength + 2)
            + varValue + " " + varUnit + "                   ",
            0, i
        ).
    }
}
