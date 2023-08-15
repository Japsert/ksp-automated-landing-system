@lazyGlobal off.
clearScreen.

until false {
    local temp is getTempAtAlt(ship:altitude).
    local staticPressure is body:atm:altitudePressure(ship:altitude).
    local atmDensity is (staticPressure * body:atm:molarMass) / (constant:idealGas * temp).
    local atmDensityKPa is atmDensity * constant:atmToKPa.
    //print "temp:             " + round(temp, 2)           + " K    "       at (0, 0).
    //print "static pressure:  " + round(staticPressure, 2) + " kPa   "      at (0, 1).
    print "atm density atm:  " + atmDensity               + " kg/m^3    "  at (0, 2).
    print "atm density kpa:  " + atmDensityKPa            + " kg/m^3    "  at (0, 3).
    
    print "should match these old values:" at (0, 4).
    
    local dynamicPressureAtm is ship:dynamicPressure.
    local sqrVelocity is ship:velocity:surface:sqrMagnitude.
    local atmDensity is (2 * dynamicPressureAtm) / sqrVelocity.
    local atmDensityKPa is atmDensity * constant:atmToKPa.
    print "atm density atm:  " + atmDensity               + " kg/m^3    " at (0, 5).
    print "atm density kpa:  " + atmDensityKPa            + " kPa    "    at (0, 6).
    wait 0.
}

function getTempAtAlt {
    local parameter alt_.
    
    if alt_ < 0 {
        print "ERROR: altitude must be greater than or equal to 0. Returning getTempAtAlt(0)".
        return getTempAtAlt(0).
    }
    
    if not body:atm:exists return 0.
    if body:atm:exists and body:atm:height < alt_ return 0.
    
    local lookupTable is list(
        lexicon(
            "start", 0,
            "end", 8814,
            "x^3", 2.7706e-11,
            "x^2", -4.3756e-07,
            "x^1", -8.1137e-03,
            "x^0", 309.6642
        ),
        lexicon(
            "start", 8814,
            "end", 16048,
            "x^2", 8.6216e-08,
            "x^1", -3.0887e-03,
            "x^0", 243.8136
        ),
        lexicon(
            "start", 16048,
            "end", 25735,
            "x^1", 1.2399e-03,
            "x^0", 196.7535
        ),
        lexicon(
            "start", 25735,
            "end", 37877,
            "x^3", -4.8140e-12,
            "x^2", 4.5867e-07,
            "x^1", -1.0577e-02,
            "x^0", 279.1508
        ),
        lexicon(
            "start", 37877,
            "end", 41120,
            "x^0", 274.9698
        ),
        lexicon(
            "start", 41120,
            "end", 57439,
            "x^1", -3.4328e-03,
            "x^0", 416.1255
        ),
        lexicon(
            "start", 57439,
            "end", 61412,
            "x^3", -7.5739e-11,
            "x^2", 1.3956e-05,
            "x^1", -8.5603e-01,
            "x^0", 17697.6256
        ),
        lexicon(
            "start", 61412,
            "end", 63440,
            "x^3", -7.5735e-11,
            "x^2", 1.3955e-05,
            "x^1", -8.5596e-01,
            "x^0", 17695.7926
        ),
        lexicon(
            "start", 63440,
            "end", 68792,
            "x^3", 2.1427e-11,
            "x^2", -4.4821e-06,
            "x^1", 3.1011e-01,
            "x^0", -6884.9892
        ),
        lexicon(
            "start", 68792,
            "end", 70000,
            "x^0", 212.9276
        )
    ).
    
    for segment in lookupTable {
        if alt_ >= segment:start and alt_ < segment:end {
            local returnValue is 0.
            if segment:hasKey("x^3")
                set returnValue to returnValue + segment["x^3"] * alt_^3.
            if segment:hasKey("x^2")
                set returnValue to returnValue + segment["x^2"] * alt_^2.
            if segment:hasKey("x^1")
                set returnValue to returnValue + segment["x^1"] * alt_^1.
            if segment:hasKey("x^0")
                set returnValue to returnValue + segment["x^0"].
            return returnValue.
        }
    }
    print "ERROR: no valid temperature found for altitude " + alt_ + ". Returning 0.0.".
    return 0.0.
}
