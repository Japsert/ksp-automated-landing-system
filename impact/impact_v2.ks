@lazyGlobal off.
clearVecDraws().


// Logging and debugging
global doLog is true.
global logPath is "0:/impact/impact.log".
// log file should have "time,lat,lng" on the first line.
global runName is "RK2, no drag, dt=5".
if doLog log "--- " + runName to logPath. // new run marker

global DO_INITIAL_BURN is true.

global DEBUG_LINE is 10.
global VAR_LINE is 22.

global errorBuffer is list().
global ERROR_LINE is 26.
global errorCount is 0.
global printErrors is false.

global drawnImpactVector is vecDraw().


// Constants
global DELTA_TIME is 5.
global MAX_ITERATIONS is 150.


// Initial sub-orbital burn to plot impact position over time
if DO_INITIAL_BURN and not (ship:apoapsis > 40000) { // DEBUG
    clearScreen. print "Burning until apoapsis >= 50 km...".
    if shouldStage() stage.
    lock throttle to 1.
    lock steering to heading(90, 80, 270).
    when ship:verticalSpeed >= 5 then legs off. 
    wait until ship:verticalSpeed >= 50.
    lock steering to srfPrograde. // gravity turn
    wait until ship:apoapsis >= 50000.
    clearScreen. print "Apoapsis reached 50 km, stopping burn and setting SAS to surface retrograde.".
    lock throttle to 0.
    lock steering to srfRetrograde.
    wait 5. // wait for ship to turn around
}

// Now coasting until impact. Calculate impact position every tick
clearScreen.
global start is time:seconds.
until false {
    local impact is getImpactPos(
        ship:geoPosition, ship:altitude, ship:velocity:surface
    ).
    
    // DEBUG: if impact found, draw vector to impact position and print coords
    if impact:isFound {
        local impactPos is impact:position.
        local impactAlt is impact:altitude.
        local iterations is impact:iterations.
        set drawnImpactVector to vecDraw(
            ship:position, impactPos:altitudePosition(impactAlt),
            red, "impact", 1, true
        ).
        print "Impact found in " + iterations + "/" + MAX_ITERATIONS + " iterations!    " at (0, DEBUG_LINE).
        print "lat: " + impactPos:lat + "    " at (0, DEBUG_LINE+1).
        print "lng: " + impactPos:lng + "    " at (0, DEBUG_LINE+2).
        print "alt: " + impactAlt + "    " at (0, DEBUG_LINE+3).
        
        // Logging
        if doLog log list(
            (time-start):seconds, impactPos:lat, impactPos:lng
        ):join(",") to logPath.
    } else {
        set drawnImpactVector to vecDraw().
        print "No impact found in " + MAX_ITERATIONS + " iterations.    " at (0, DEBUG_LINE).
        print "                                  " at (0, DEBUG_LINE+1).
        print "                                  " at (0, DEBUG_LINE+2).
        print "                                  " at (0, DEBUG_LINE+3).
    }
    
    wait 0.
}


// Checks if we should stage to be able to burn.
// Returns true if there is an ignited engine, false if not.
function shouldStage {
    local engines is list().
    list engines in engines.
    for engine in engines {
        if engine:ignition return false.
    }
    return true.
}


function calculateAccelerationNoDrag {
    local parameter prevPos.
    local parameter prevAlt.
    local parameter prevVelVec.
    
    // Gravity vector
    local g is body:mu / (body:radius + prevAlt)^2.
    local gravForce is g * ship:mass. // kN
    local gravForceVec is gravForce * -ship:up:vector.
    
    // Total force vector
    local totalForceVec is gravForceVec. // kN
    
    // Acceleration vector
    local accVec is totalForceVec / ship:mass. // Constant mass, no burn yet
    
    return accVec.
}

function calculateAcceleration {
    local parameter prevPos.
    local parameter prevAlt.
    local parameter prevVelVec.
    
    // Gravity vector
    local g is body:mu / (body:radius + prevAlt)^2.
    local gravForce is g * ship:mass. // kN
    local gravForceVec is gravForce * -ship:up:vector.
    
    // Drag vector
    local temperature is lookUpTemp(prevAlt).
    local staticPressure is body:atm:altitudePressure(prevAlt).
    local atmDensity is (staticPressure * body:atm:molarMass)
                            / (constant:idealGas * temperature).
    local atmDensityKPa is atmDensity * constant:atmToKPa.
    
    local sqrVelocity is prevVelVec:sqrMagnitude.
    
    local bulkModulus is staticPressure * body:atm:adiabaticIndex.
    local speedOfSound is sqrt(bulkModulus / atmDensity).
    local vel is prevVelVec:mag.
    local machNumber is vel / speedOfSound.
    local CdA is lookUpCdA(machNumber).
    
    local dragForce is 1/2 * atmDensityKPa * sqrVelocity * CdA. // kN
    local dragForceVec is dragForce * -prevVelVec:normalized.
    
    // Total force vector
    local totalForceVec is gravForceVec + dragForceVec. // kN
    
    // Acceleration vector
    local accVec is totalForceVec / ship:mass. // Constant mass, no burn yet
    
    return accVec.
}


// Returns the position, altitude and velocity vector that a ship with the
// given position, altitude and velocity vector would have after one time step.
function updatePosAltVelRK1 {
    local parameter pos.
    local parameter alt_.
    local parameter velVec.
    
    // Determine current acceleration
    local accVec is calculateAccelerationNoDrag(pos, alt_, velVec).
    // Add acceleration to velocity vector
    local newVelVec is velVec + accVec * DELTA_TIME.
    // Update pos, alt and vel, accounting for curvature of the planet
    local positionChangeVec is newVelVec * DELTA_TIME.
    local vecToNewPos is pos:altitudePosition(alt_) + positionChangeVec.
    local newPos to body:geoPositionOf(vecToNewPos).
    local newAlt to body:altitudeOf(vecToNewPos).
    
    return lexicon(
        "position", newPos,
        "altitude", newAlt,
        "velocityVector", newVelVec
    ).
}

// 
function updatePosAltVelRK2 {
    local parameter prevPos.
    local parameter prevAlt.
    local parameter prevVelVec.
    
    // Acceleration at the start of the interval
    local accVec1 is calculateAccelerationNoDrag(prevPos, prevAlt, prevVelVec).
    
    // Pos, alt and vel vector at the end of the interval
    local velVec1 is prevVelVec + accVec1 * DELTA_TIME.
    local positionChangeVec1 is velVec1 * DELTA_TIME.
    local vecToPos1 is prevPos:altitudePosition(prevAlt) + positionChangeVec1.
    local pos1 is body:geoPositionOf(vecToPos1).
    local alt1 is body:altitudeOf(vecToPos1).
    
    // Acceleration at the end of the interval
    local accVec2 is calculateAccelerationNoDrag(pos1, alt1, velVec1).
    
    // Average accelerations
    local accVecAvg is (accVec1 + accVec2) / 2.
    
    // Update pos, alt and vel vector, accounting for curvature of the planet
    local newVelVec is prevVelVec + accVecAvg * DELTA_TIME.
    local positionChangeVec is newVelVec * DELTA_TIME.
    local vecToNewPos is prevPos:altitudePosition(prevAlt) + positionChangeVec.
    local newPos to body:geoPositionOf(vecToNewPos).
    local newAlt to body:altitudeOf(vecToNewPos).
    
    return lexicon(
        "position", newPos,
        "altitude", newAlt,
        "velocityVector", newVelVec
    ).
}


// If the given location (pos/alt) is below the surface, interpolates between
// the previous location and the current location to estimate the actual impact
// position, and returns a lexicon with the position and altitude.
function hasImpactedSurface {
    local parameter newPos.
    local parameter newAlt.
    local parameter pos.
    local parameter alt_.
    
    local posImpactHeight is max(newPos:terrainHeight, 0).
    if newAlt > posImpactHeight return lexicon(
        "impacted", false,
        "position", 0,
        "altitude", 0
    ).
    
    // The location is below the surface, interpolate between pos and prevPos
    // to estimate landing position
    local prevPosImpactHeight is max(pos:terrainHeight, 0).
    local averageImpactHeight is (posImpactHeight + prevPosImpactHeight) / 2.
    local altRatio is (alt_ - averageImpactHeight) / (alt_ - newAlt).
    local interpolatedPos is latLng(
        pos:lat + (newPos:lat - pos:lat) * altRatio,
        pos:lng + (newPos:lng - pos:lng) * altRatio
    ).
    return lexicon(
        "impacted", true,
        "position", interpolatedPos,
        "altitude", max(interpolatedPos:terrainHeight, 0)
    ).
}


function getImpactPos {
    local parameter initialPos.
    local parameter initialAlt.
    local parameter initialVelVec.
    
    local pos is initialPos.
    local alt_ is initialAlt.
    local velVec is initialVelVec.
    
    local i is 0.
    local reachedGround is false.
    local maxIterationsReached is false.
    local impactPos is false.
    local impactAlt is false.
    
    until reachedGround or maxIterationsReached {
        // Get new position, altitude and velocity vector based on current state
        local newPosAltVel is updatePosAltVelRK1(pos, alt_, velVec).
        local newPos is newPosAltVel:position.
        local newAlt is newPosAltVel:altitude.
        local newVelVec is newPosAltVel:velocityVector.
        
        // Check if we have impacted
        local surfaceImpact is hasImpactedSurface(newPos, newAlt, pos, alt_).
        if surfaceImpact:impacted {
            set reachedGround to true.
            set impactPos to surfaceImpact:position.
            set impactAlt to surfaceImpact:altitude.
        }
        
        // Check if we should give up
        set i to i + 1.
        if i >= MAX_ITERATIONS set maxIterationsReached to true.
        
        // Update pos, alt and velVec for next iteration
        set pos to newPos.
        set alt_ to newAlt.
        set velVec to newVelVec.
    }
    
    return lexicon(
        "isFound", reachedGround,
        "position", impactPos,
        "altitude", impactAlt,
        "iterations", i
    ).
}


// Look up the temperature at a given altitude in a lookup table.
function lookUpTemp {
    local parameter alt_.
    
    if not body:atm:exists return 0.
    if alt_ > body:atm:height return 0.
    
    if alt_ < 0 {
        printError("altitude must be greater than or equal to 0. Returning ground temperature.").
        return lookUpTemp(0).
    }
    
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
    printError("No valid temperature found for altitude " + alt_ + ". Returning 0.0.").
    return 0.0.
}


// Look up the drag coefficient at a given Mach number in a lookup table.
function lookUpCdA {
    local parameter machNumber.
    
    if not body:atm:exists return 0.
    if ship:altitude > body:atm:height return 0.
    
    if machNumber < 0 {
        printError("machNumber < 0! Returning CdA at standstill.").
        return lookUpCdA(0).
    }
    
    if machNumber >= 6.8 {
        printError("machNumber >= 6.8! Returning CdA at Mach 6.799.").
        return lookUpCdA(6.799).
    }
    
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
            local returnValue is 0.
            if segment:hasKey("x^3")
                set returnValue to returnValue + segment["x^3"] * machNumber^3.
            if segment:hasKey("x^2")
                set returnValue to returnValue + segment["x^2"] * machNumber^2.
            if segment:hasKey("x^1")
                set returnValue to returnValue + segment["x^1"] * machNumber^1.
            if segment:hasKey("x^0")
                set returnValue to returnValue + segment["x^0"].
            return returnValue.
        }
    }
    printError("No valid CdA found for machNumber " + machNumber + ". Returning 0.0.").
    return 0.0.
}


// DEBUG: helper function
function printVars {
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
        printLine(
            (varName + ": "):padright(maxVarLength + 2)
            + varValue + " " + varUnit, VAR_LINE + i
        ).
    }
}

// DEBUG: helper function
function printLine {
    local parameter string.
    local parameter line.
    
    set string to string:padright(terminal:width).
    print string at (0, line).
}

// DEBUG: helper function
function printError {
    local parameter msg.
    
    if not printErrors return.
    
    local height is terminal:height - 1. // last line is not used?
    
    function spaceForNewError {
        local parameter newError.
        
        local i is ERROR_LINE.
        for error in errorBuffer {
            local lineCount is ceiling(error:length / terminal:width).
            set i to i + lineCount.
        }
        local newErrorLineCount is ceiling(newError:length / terminal:width).
        
        return i + newErrorLineCount <= height.
    }
    
    // Prefix error count
    set errorCount to errorCount + 1.
    local errorNumberPrefix is "[" + errorCount + "] ".
    local error is errorNumberPrefix + msg.
    
    // Remove old messages if necessary
    until spaceForNewError(error) {
        errorBuffer:remove(0).
    }
    errorBuffer:add(error).
    
    // Print the buffer
    local i is ERROR_LINE.
    for error in errorBuffer {
        printLine(error, i).
        local lineCount is ceiling(error:length / terminal:width).
        set i to i + lineCount.
    }
    
    // Clear the rest of the lines
    until i >= height {
        printLine("", i).
        set i to i + 1.
    }
}
