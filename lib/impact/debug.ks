@lazyGlobal off.
clearScreen.
clearVecDraws().

// DEBUG
local drawDebugVectors is false.
when terminal:input:hasChar then {
    local c is terminal:input:getChar().
    if c = "w" {
        set drawDebugVectors to true.
    } else if c = "c" {
        clearVecDraws().
    }
    preserve.
}

local mu is body:mu.
local atm is body:atm.
local atmHeight is atm:height.
local engine is ship:engines[0].

function getAccVec { // TODO: optimize
    local parameter posVec.
    local parameter velVec. // orbital velocity
    
    // Convert non-inertial velocity to inertial velocity
    local velVecSrf is velVec - vCrs(body:angularVel, posVec - body:position).
    
    // Gravity
    local centerToPosVec is posVec - body:position.
    local alt_ is centerToPosVec:mag - body:radius.
    
    local g is mu / centerToPosVec:sqrMagnitude.
    local gravAccVec is g * -centerToPosVec:normalized.
    
    //if alt_ >= atmHeight return gravAccVec.
    
    //// Drag
    //local staticPressure is atm:altitudePressure(alt_).
    //local atmDensityAtm is
    //    (staticPressure * atmMolarMass) / (idealGas * lookUpTemp(alt_)).
    //local atmDensityKPa is atmDensityAtm * atmToKPa.
    
    //local CdA is lookUpCdA(
    //    velVecSrf:mag / sqrt(staticPressure * atmAdbIdx / atmDensityAtm)
    //).
    
    //local dragAcc is 0.5 * atmDensityKPa * velVecSrf:sqrMagnitude * CdA.
    //local dragAccVec is dragAcc * -velVecSrf:normalized.
    
    //return gravAccVec + dragAccVec.
    
    return gravAccVec.
}

function getBurnAccVec { // TODO: optimize
    local parameter posVec.
    local parameter velVec. // orbital velocity
    
    local centerToPosVec is posVec - body:position.
    local alt_ is centerToPosVec:mag - body:radius.
    
    // Convert non-inertial velocity to inertial velocity
    local velVecSrf is velVec - vCrs(body:angularVel, centerToPosVec).
    
    // Gravity
    local g is mu / centerToPosVec:sqrMagnitude.
    local gravAccVec is g * -centerToPosVec:normalized.
    
    // Thrust
    local staticPressure is atm:altitudePressure(alt_).
    local thrustAcc is engine:possibleThrustAt(staticPressure) / mass.
    local thrustAccVec is thrustAcc * -velVecSrf:normalized.
    
    if alt_ >= atmHeight return gravAccVec + thrustAccVec.
    
    // Drag
    //local atmDensityAtm is
    //    (staticPressure * atmMolarMass) / (idealGas * lookUpTemp(alt_)).
    //local atmDensityKPa is atmDensityAtm * atmToKPa.
    
    //local CdA is lookUpCdA(
    //    velVecSrf:mag / sqrt(staticPressure * atmAdbIdx / atmDensityAtm)
    //).
    
    //local dragAcc is 
    //    0.5 * atmDensityKPa * velVecSrf:sqrMagnitude * CdA.
    //local dragAccVec is dragAcc * -velVecSrf:normalized.
    
    //return gravAccVec + dragAccVec + thrustAccVec.
    return gravAccVec + thrustAccVec.
}

// DEBUG
function drawDebugVec {
    local parameter newGeopos.
    local parameter newAlt.
    local parameter geopos.
    local parameter alt_.
    local parameter color.
    
    local vecToNewPos is newGeopos:altitudePosition(newAlt).
    local vecToOldPos is geopos:altitudePosition(alt_).
    local vec is vecToNewPos - vecToOldPos.
    return vecDraw(
        { return geopos:altitudePosition(alt_). },
        vec, color, "", 1, true
    ).
}

// Initial burn
if ship:status = "prelaunch" {
    stage.
    lock steering to heading(90, 70).
    lock throttle to 1.
    wait 1.
    legs off.
    until kuniverse:timewarp:rate = 4 {
        set kuniverse:timewarp:rate to 4.
        wait 0.
    }
    wait until ship:apoapsis >= 58000.
    set kuniverse:timewarp:rate to 1.
    wait until ship:apoapsis >= 65000.
    lock throttle to 0.
    lock steering to srfPrograde.
}

local dT is 15.
local halfDT is dT / 2.
local sixthDT is dT / 6.
local bodyRotationPerStep is 2 * constant:pi / body:rotationPeriod * constant:radToDeg * dT.
local maxBurnIterations is 20.
local burnDT is 5.
print "burn dt: " + burnDT + "s" at (0, 0).
local bodyRotationPerBurnStep is 2 * constant:pi / body:rotationPeriod * constant:radToDeg * burnDT.
local i is 0.
until false {
    set i to i + 1.
    local drawDebugVectorsThisIteration is drawDebugVectors.
    
    // calculate the expected burn end location using RK4
    local burnPosVec is ship:position.
    local burnVelVec is ship:velocity:orbit.
    local burnGeopos is body:geopositionOf(burnPosVec).
    local burnAlt is body:altitudeOf(burnPosVec).
    set burnGeopos to latLng(burnGeopos:lat, burnGeopos:lng - bodyRotationPerStep * i).
    
    local j is 0.
    local burnEnded is false.
    local maxBurnIterationsReached is false.
    
    until burnEnded or maxBurnIterationsReached {
        set j to j + 1.
        
        if j = 1 print "current lat/lng: " + round(burnGeopos:lat, 4) + ", " + round(burnGeopos:lng, 4) at (0, 5).
        
        // Update position and velocity using RK4
        local k1VelVec is burnVelVec.
        local k1AccVec is getBurnAccVec(burnPosVec, k1VelVec).
        local k2VelVec is burnVelVec + k1AccVec * halfDT.
        local k2AccVec is getBurnAccVec(burnPosVec + k1VelVec * halfDT, k2VelVec).
        local k3VelVec is burnVelVec + k2AccVec * halfDT.
        local k3AccVec is getBurnAccVec(burnPosVec + k2VelVec * halfDT, k3VelVec).
        local k4VelVec is burnVelVec + k3AccVec * dT.
        local k4AccVec is getBurnAccVec(burnPosVec + k3VelVec * dT, k4VelVec).
        if drawDebugVectorsThisIteration and j = 1 {
            vecDraw({ return burnGeopos:altitudePosition(burnAlt). }, k1VelVec, red, "", 1, true).
            vecDraw({ return burnGeopos:altitudePosition(burnAlt). }, k2VelVec, green, "", 1, true).
            vecDraw({ return burnGeopos:altitudePosition(burnAlt). }, k3VelVec, blue, "", 1, true).
            vecDraw({ return burnGeopos:altitudePosition(burnAlt). }, k4VelVec, yellow, "", 1, true).
        }
        
        print round(k1VelVec:mag, 2) + "m/s, " + round(k2VelVec:mag, 2) + "m/s, " +
            round(k3VelVec:mag, 2) + "m/s, " + round(k4VelVec:mag, 2) + "m/s" at (0, 6).
        local newBurnPosVec is
            burnPosVec + sixthDT * (k1VelVec + 2 * k2VelVec + 2 * k3VelVec + k4VelVec).
        if j = 1 print "after 1 iteration, next step is " + newBurnPosVec:mag + "m away" at (0, 10).
        if drawDebugVectorsThisIteration and j = 1
            vecDraw(ship:position, newBurnPosVec - ship:position, red, "", 1, true).
        local newBurnVelVec is
            burnVelVec + sixthDT * (k1AccVec + 2 * k2AccVec + 2 * k3AccVec + k4AccVec).
        
        // Check if position under surface
        
        if newBurnVelVec:mag >= burnVelVec:mag set burnEnded to true.
        
        if j >= maxBurnIterations set maxBurnIterationsReached to true.
        
        // DEBUG
        local newBurnGeopos is body:geopositionOf(newBurnPosVec).
        local newBurnAlt is body:altitudeOf(newBurnPosVec).
        set newBurnGeopos to latLng(newBurnGeopos:lat,
            newBurnGeopos:lng - bodyRotationPerStep * i - bodyRotationPerBurnStep * j).
        if drawDebugVectorsThisIteration and j = 1
            drawDebugVec(newBurnGeopos, newBurnAlt, burnGeopos, burnAlt, yellow).
        
        // Update variables
        set burnPosVec to newBurnPosVec.
        set burnVelVec to newBurnVelVec.
        set burnGeopos to newBurnGeopos.
        set burnAlt to newBurnAlt.
    }
    if burnEnded {
        print "burn ended                 " at (0, 20).
    } else if maxBurnIterationsReached {
        print "max burn iterations reached" at (0, 20).
    }
    
    set drawDebugVectors to false.
    wait 0.
}
