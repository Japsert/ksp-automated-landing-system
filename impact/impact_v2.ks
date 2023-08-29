@lazyGlobal off.
clearVecDraws().


local parameter DO_INITIAL_BURN is false.
local parameter DO_LOG is false.

// Logging and debugging
global logPath is "0:/impact/impact.log".
global runName is "RK2, drag, dt=5".
if DO_LOG log "--- " + runName to logPath. // new run marker

global DEBUG_LINE is 10.
global VAR_LINE is 20.

global errorBuffer is list().
global ERROR_LINE is 26.
global errorCount is 0.
global printErrors is false.

global drawnImpactVector is vecDraw().

// DEBUG: draw trajectory vectors when 'w' is pressed
local drawDebugVectors is false.
when terminal:input:hasChar then {
    if terminal:input:getChar() = "w" {
        set drawDebugVectors to true.
    }
    preserve.
}


// Constants
global TIME_STEP is 5.
global MAX_ITERATIONS is 150.


local tempLookupTable is list(
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

local cdaLookupTable is list(
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
local tr is addons:tr.
until false {
    local drawDebugVectorsThisIteration is drawDebugVectors.
    local impact is getImpactPos(
        ship:position, ship:velocity:orbit, "RK2", drawDebugVectorsThisIteration
    ).
    set drawDebugVectors to false.
    
    // DEBUG: if impact found, draw vector to impact position and print coords
    if impact:isFound {
        local impactPos is impact:geoposition.
        local impactAlt is impact:altitude.
        local iterations is impact:iterations.
        set drawnImpactVector to vecDraw(
            ship:position, impactPos:altitudePosition(impactAlt),
            red, "", 1, true
        ).
        print "Impact found in " + iterations + "/" + MAX_ITERATIONS + " iterations!    " at (0, DEBUG_LINE).
        print "lat: " + round(impactPos:lat, 6) + "    " at (0, DEBUG_LINE+1).
        print "lng: " + round(impactPos:lng, 6) + "    " at (0, DEBUG_LINE+2).
        print "alt: " + round(impactAlt, 2) + "    " at (0, DEBUG_LINE+3).
        
        // Logging
        if DO_LOG log list(
            (time-start):seconds, impactPos:lat, impactPos:lng
        ):join(",") to logPath.
    } else {
        set drawnImpactVector to vecDraw().
        print "No impact found in " + MAX_ITERATIONS + " iterations.    " at (0, DEBUG_LINE).
        print "                                  " at (0, DEBUG_LINE+1).
        print "                                  " at (0, DEBUG_LINE+2).
        print "                                  " at (0, DEBUG_LINE+3).
    }
    
    // DEBUG: Trajectories impact estimation
    if tr:available {
        if tr:hasImpact {
            local impactPos is tr:impactPos.
            print "Trajectories impact position:          " at (0, DEBUG_LINE+5).
            print "lat: " + round(impactPos:lat, 6) + "    " at (0, DEBUG_LINE+6).
            print "lng: " + round(impactPos:lng, 6) + "    " at (0, DEBUG_LINE+7).
        } else {
            print "Trajectories impact position: not found" at (0, DEBUG_LINE+5).
            print "                                  " at (0, DEBUG_LINE+6).
            print "                                  " at (0, DEBUG_LINE+7).
        }
    }
    
    wait 0.
}


function calculateAcceleration {
    local parameter posVec.
    local parameter velVec. // orbital velocity
    local parameter accountForDrag is true.
    local parameter i is -1.
    
    // The velVec parameter is in the orbital frame, so we need to convert it
    // to the surface frame to get the airspeed.
    // Thanks to nuggreat for the explanation:
    //  The cross product of the angular velocity vector of the body and the
    //  radius vector to the position of that velocity vector will produce the
    //  difference vector between orbital and surface.

    local velVecSrf is velVec - vcrs(body:angularVel, posVec - body:position).
    
    // Calculate altitude
    local centerToPosVec is (posVec - body:position).
    local altFromCenter is centerToPosVec:mag.
    local alt_ is altFromCenter - body:radius.

    // Determine acceleration at altitude
    local g is (body:mu)/(altFromCenter)^2.
    local gravAccVec is g * -centerToPosVec:normalized.
    
    if not accountForDrag return gravAccVec.
    
    // Drag vector
    local temperature is lookUpTemp(alt_).
    local staticPressure is body:atm:altitudePressure(alt_).
    local atmDensity is (staticPressure * body:atm:molarMass)
                            / (constant:idealGas * temperature).
    local atmDensityKPa is atmDensity * constant:atmToKPa.
    
    local sqrVelocity is velVecSrf:sqrmagnitude.
    
    local bulkModulus is staticPressure * body:atm:adiabaticIndex.
    local speedOfSound is sqrt(bulkModulus / atmDensity).
    local vel is velVecSrf:mag.
    local machNumber is vel / speedOfSound.
    local CdA is lookUpCdA(machNumber).
    
    local dragForce is 1/2 * atmDensityKPa * sqrVelocity * CdA. // kN
    local dragAcc is dragForce / mass. // constant mass, no burn yet
    local dragAccVec is dragAcc * -velVecSrf:normalized.
    
    // DEBUG: print variables
    if i = 1 printVars(list(
        list("alt", alt_, "m"),
        list("temperature", temperature, "K"),
        list("staticPressure", staticPressure, "Pa"),
        list("atmDensityKPa", atmDensityKPa, "kg/km^3"),
        list("speedOfSound", speedOfSound, "m/s"),
        list("vel", vel, "m/s"),
        list("machNumber", machNumber, ""),
        list("CdA", CdA, "m^2"),
        list("dragForce", dragForce, "kN"),
        list("dragAcc", dragAcc, "m/s^2")
    )).
    
    return gravAccVec + dragAccVec.
}


// Returns the position, altitude and velocity vector that a ship with the
// given position, altitude and velocity vector would have after one time step.
function updatePosVelRK1 {
    local parameter posVec.
    local parameter velVec.
    local parameter i is -1. // DEBUG
    
    local accVec is calculateAcceleration(posVec, velVec, true, i).
    
    // Calculate vector pointing to next position (starting from current
    // position vector)
    local positionChangeVec is
        velVec * TIME_STEP + 0.5 * accVec * TIME_STEP^2.
    
    // Add this vector to position vector
    local newPosVec is posVec + positionChangeVec.
    
    // Calculate new velocity vector
    local newVelVec is velVec + accVec * TIME_STEP.
    
    return lexicon(
        "position", newPosVec,
        "velocity", newVelVec
    ).
}

function updatePosVelRK2 {
    local parameter posVec.
    local parameter velVec.
    
    // Acceleration at the start of the interval
    local accVecStart is calculateAcceleration(posVec, velVec, true).
    
    // Position vector and velocity vector at end of time step
    local positionChangeVecTemp is
        velVec * TIME_STEP + 1/2 * accVecStart * TIME_STEP^2.
    local posVecEnd is posVec + positionChangeVecTemp.
    local velVecEnd is velVec + accVecStart * TIME_STEP.
    
    // Acceleration at end of time step
    local accVecEnd is calculateAcceleration(posVecEnd, velVecEnd, true).
    
    // Average accelerations
    local accVecAvg is (accVecStart + accVecEnd) / 2.
    
    // RK1
    local positionChangeVec is
        velVec * TIME_STEP + 1/2 * accVecAvg * TIME_STEP^2.
    local newPosVec is posVec + positionChangeVec.
    local newVelVec is velVec + accVecAvg * TIME_STEP.
    
    return lexicon(
        "position", newPosVec,
        "velocity", newVelVec
    ).
}


// If the given location (pos/alt) is below the surface, interpolates between
// the previous location and the new location to estimate the actual impact
// position, and returns a lexicon with the position and altitude.
function checkImpact {
    local parameter newGeopos.
    local parameter newAlt.
    local parameter geopos.
    local parameter alt_.
    
    local newGeoposImpactHeight is max(newGeopos:terrainHeight, 0).
    if newAlt > newGeoposImpactHeight return lexicon(
        "isImpact", false,
        "geoposition", false,
        "altitude", false
    ).
    
    // The location is below the surface, interpolate between pos and newPos
    // to estimate landing position
    local oldGeoposImpactHeight is max(geopos:terrainHeight, 0).
    local averageImpactHeight is (newGeoposImpactHeight + oldGeoposImpactHeight) / 2.
    local altRatio is (alt_ - averageImpactHeight) / (alt_ - newAlt).
    local interpolatedGeopos is latLng(
        geopos:lat + (newGeopos:lat - geopos:lat) * altRatio,
        geopos:lng + (newGeopos:lng - geopos:lng) * altRatio
    ).
    return lexicon(
        "isImpact", true,
        "geoposition", interpolatedGeopos,
        "altitude", max(interpolatedGeopos:terrainHeight, 0)
    ).
}


function drawDebugVec {
    local parameter geopos.
    local parameter alt_.
    local parameter vec.
    local parameter i.
    
    vecDraw(
        { return geopos:altitudePosition(alt_). }, vec,
        blue, i, 1, true
    ).
}


function getImpactPos {
    local parameter initialPosVec is ship:position.
    local parameter initialVelVec is ship:velocity:orbit.
    local parameter integrationMethod is "RK2".
    local parameter drawDebugVecs is false. // DEBUG
    
    local posVec is initialPosVec.
    local velVec is initialVelVec.
    local alt_ is body:altitudeOf(initialPosVec).
    local correctedGeopos is body:geopositionOf(initialPosVec). // DEBUG
    
    local i is 0.
    local reachedGround is false.
    local maxIterationsReached is false.
    local impactGeopos is false.
    local impactAlt is false.
    
    until reachedGround or maxIterationsReached {
        set i to i + 1.
        
        // Determine new position vector and velocity vector based on current state
        local newPosVel is lexicon().
        if integrationMethod = "RK1"
            set newPosVel to updatePosVelRK1(posVec, velVec, i).
        else if integrationMethod = "RK2"
            set newPosVel to updatePosVelRK2(posVec, velVec).
        else
            printError("Invalid integration method '" + integrationMethod + "'. Using RK2.").
            set newPosVel to updatePosVelRK2(posVec, velVec).
        local newPosVec is newPosVel:position.
        local newVelVec is newPosVel:velocity.
        
        // Convert position vector to geoposition/altitude and correct for body rotation
        local newGeopos is body:geopositionOf(newPosVec).
        local newAlt is body:altitudeOf(newPosVec).
        local bodyRotationPerStep is body:angularVel:mag * constant:radToDeg * TIME_STEP. // TODO: precompute using body:rotationPeriod (see debug_v2.ks)
        local bodyRotationSinceStart is bodyRotationPerStep * i.
        local correctedNewGeopos is latLng(newGeopos:lat, newGeopos:lng - bodyRotationSinceStart).
        
        // Check if we have impacted
        local impact is checkImpact(correctedNewGeopos, newAlt, correctedGeopos, alt_).
        if impact:isImpact {
            set reachedGround to true.
            set impactGeopos to impact:geoposition.
            set impactAlt to impact:altitude.
        }
        
        // Check if we should give up
        if i >= MAX_ITERATIONS set maxIterationsReached to true.
        
        // DEBUG: Draw debug vector
        // Draw vector from rotation corrected geocoordinates/altitude from
        // previous iteration to rotation corrected geocoordinates/altitude from
        // current iteration
        local srfPosVec is correctedGeopos:altitudePosition(alt_).
        local newSrfPosVec is correctedNewGeopos:altitudePosition(newAlt).
        local vecToNewPos is newSrfPosVec - srfPosVec.
        if drawDebugVecs drawDebugVec(correctedGeopos, alt_, vecToNewPos, i).

        // Set position vector and velocity vector for next iteration
        set posVec to newPosVec.
        set velVec to newVelVec.
        set alt_ to newAlt.
        set correctedGeopos to correctedNewGeopos. // DEBUG
    }
    
    return lexicon(
        "isFound", reachedGround,
        "geoposition", impactGeopos,
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
    
    for segment in tempLookupTable {
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
    
    for segment in cdaLookupTable {
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
