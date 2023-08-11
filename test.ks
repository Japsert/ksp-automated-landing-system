global ATM_TO_PA is constant:atmtokpa * 1000.

until false {
    local horizontalVelocity is ship:groundspeed.
    local verticalVelocity is ship:verticalspeed.
    local alt_ is ship:altitude.
    local velocityVector is ship:velocity:surface.
    set drawnVelocityVector to vecDraw(
        ship:position, velocityVector, red, "velocity", 1, true
    ).
    global TIME_INTERVAL is 10.
    global VAR_LINE is 20.

    // calculate drag vector (in opposite direction of velocity)
    // drag equation: FD = 1/2 * rho * v^2 * Cd * A
    local dynamicPressureAtm is ship:dynamicPressure.
    local dynamicPressurePa is dynamicPressureAtm * ATM_TO_PA.
    local sqrVelocity is ship:velocity:surface:sqrmagnitude.
    local atmDensity is (2 * dynamicPressureAtm) / sqrVelocity.
    local atmDensityPa is atmDensity * ATM_TO_PA.

    local vel is sqrt(horizontalVelocity^2 + verticalVelocity^2).

    local staticPressure is body:atm:altitudePressure(alt_).
    local bulkModulus is staticPressure * body:atm:adiabaticindex.
    local speedOfSound is sqrt(bulkModulus / atmDensity).
    local machNumber is vel / speedOfSound.
    local CdA is getCdA(machNumber).

    local dragForce is 1/2 * atmDensityPa * sqrVelocity * CdA. // N
    local dragAcceleration is dragForce / ship:mass.
    local dragVector is -velocityVector:normalized * dragAcceleration.
    set drawnDragVector to vecDraw(
        ship:position, dragVector, blue, "drag", 1, true
    ).

    clearScreen.
    printVariables(
        lexicon(
            //"horizontalVelocity", horizontalVelocity,
            //"verticalVelocity", verticalVelocity,
            //"alt_", alt_,
            "sqrVelocity", sqrVelocity,
            "atmDensity", atmDensity,
            //"vel", vel,
            //"staticPressure", staticPressure,
            //"bulkModulus", bulkModulus,
            "dynamicPressureAtm", dynamicPressureAtm,
            "dynamicPressurePa", dynamicPressurePa,
            //"speedOfSound", speedOfSound,
            "machNumber", machNumber,
            "CdA", CdA,
            "dragForce", dragForce/1000,
            "dragAcceleration", dragAcceleration
        )
    ).
    
    wait 0.
}

function getCdA {
    local parameter machNumber.
    
    local lookupTable is list(
        lexicon(
            "start", 0.0,
            "end", 0.85,
            "x^2", -0.0951,
            "x^1", -0.0844,
            "x^0", 1.4157
        ),
        lexicon(
            "start", 0.85,
            "end", 1.1,
            "x^3", -177.5173,
            "x^2", 517.6693,
            "x^1", -495.1551,
            "x^0", 157.1451
        ),
        lexicon(
            "start", 1.1,
            "end", 2.0,
            "x^3", 2.3121,
            "x^2", -10.8694,
            "x^1", 15.5400,
            "x^0", -4.4169
        ),
        lexicon(
            "start", 2.0,
            "end", 2.5,
            "x^2", -0.0970,
            "x^1", 0.4727,
            "x^0", 1.1359
        ),
        lexicon(
            "start", 2.5,
            "end", 3.25,
            "x^2", 0.4388,
            "x^1", -2.0210,
            "x^0", 4.0144
        ),
        lexicon(
            "start", 3.25,
            "end", 4.25,
            "x^2", -0.1858,
            "x^1", 1.9329,
            "x^0", -2.2326
        ),
        lexicon(
            "start", 4.25,
            "end", 5.0,
            "x^2", 0.7075,
            "x^1", -5.6143,
            "x^0", 13.7052
        ),
        lexicon(
            "start", 5.0,
            "end", 6.0,
            "x^2", -0.3785,
            "x^1", 4.9739,
            "x^0", -12.0977
        ),
        lexicon(
            "start", 6.0,
            "end", 6.35,
            "x^2", -10.0028,
            "x^1", 127.2061,
            "x^0", -398.8970
        ),
        lexicon(
            "start", 6.35,
            "end", 6.8,
            "x^2", -0.3580,
            "x^1", 5.2814,
            "x^0", -13.5545
        )
    ).
    
    for segment in lookupTable {
        if machNumber >= segment:start and machNumber < segment:end {
            if segment:hasKey("x^3") {
                return segment["x^3"] * machNumber^3
                     + segment["x^2"] * machNumber^2
                     + segment["x^1"] * machNumber
                     + segment["x^0"].
            } else if segment:hasKey("x^2") {
                return segment["x^2"] * machNumber^2
                     + segment["x^1"] * machNumber
                     + segment["x^0"].
            }
        }
    }
    return 0.0.
}

// Helper function
function printVariables {
    local parameter vars. // lexicon
    
    // Determine the length of the longest variable name.
    local maxVarLength is 0.
    for var in vars:keys {
        local varLength is var:tostring:length.
        if varLength > maxVarLength {
            set maxVarLength to varLength.
        }
    }
    
    from {local i is 0.} until i = vars:length step {set i to i + 1.} do {
        local varName is vars:keys[i].
        local var is vars[varName].
        printAt(
            (varName + ": "):padright(maxVarLength + 2)
            + var + "    ",
            0, VAR_LINE + i
        ).
    }
}
