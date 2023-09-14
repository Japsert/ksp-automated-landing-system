@lazyGlobal off.
clearScreen.
clearVecDraws().

// DEBUG
local drawDebugVectors is false.
local calcBurn is false.
when terminal:input:hasChar then {
    local c is terminal:input:getChar().
    if c = "w" {
        set drawDebugVectors to true.
    } else if C = "e" {
        set calcBurn to true.
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
local burnDT is 1.
print "burn dt: " + burnDT + "s" at (0, 0).
local bodyRotationPerBurnStep is 2 * constant:pi / body:rotationPeriod * constant:radToDeg * burnDT.
until false {
    if calcBurn {
        // iterate using euler to predict burn trajectory
        local burnPosVec is ship:position.
        local burnVelVec is ship:velocity:orbit.
        local burnGeopos is body:geopositionOf(burnPosVec).
        local burnAlt is body:altitudeOf(burnPosVec).
        
        local i is 0.
        local burnEnded is false.
        
        until burnEnded {
            set i to i + 1.
            
            local burnAccVec is getBurnAccVec(burnPosVec, burnVelVec).
            local newBurnPosVec is burnPosVec + burnVelVec * burnDT + 0.5 * burnAccVec * burnDT^2.
            local newBurnVelVec is burnVelVec + burnAccVec * burnDT.
            local newBurnGeopos is body:geopositionOf(newBurnPosVec).
            set newBurnGeopos to latLng(newBurnGeopos:lat, newBurnGeopos:lng - bodyRotationPerBurnStep * i).
            local newBurnAlt is body:altitudeOf(newBurnPosVec).
            
            // If we are below the surface, interpolate to find exact landing position
            if newBurnAlt <= max(newBurnGeopos:terrainHeight, 0) {
                print "impacted at " + newBurnGeopos + " after " + i + " iterations" at (0, 1).
                set burnEnded to true.
                // Interpolate landing position
                local newBurnGeoposSurfaceAlt is max(newBurnGeopos:terrainHeight, 0).
                local oldBurnGeoposSurfaceAlt is max(burnGeopos:terrainHeight, 0).
                local averageBurnSurfaceAlt is
                    (oldBurnGeoposSurfaceAlt + newBurnGeoposSurfaceAlt) / 2.
                local altRatio is
                    (burnAlt - averageBurnSurfaceAlt) / (burnAlt - newBurnAlt).
                set landingGeopos to latLng(
                    burnGeopos:lat + (newBurnGeopos:lat - burnGeopos:lat) * altRatio,
                    burnGeopos:lng + (newBurnGeopos:lng - burnGeopos:lng) * altRatio
                ).
                set landingAlt to max(landingGeopos:terrainHeight, 0).
                set burnStartAlt to body:altitudeOf(newPosVec).
            }
            
            // If the velocity has come to a stop or the vertical velocity is zero or
            // positive, the burn has ended, but we haven't reached the surface.
            if newBurnVelVec:mag >= burnVelVec:mag  {
            //or (newBurnVelVec - vectorExclude(newBurnPosVec - body:position, newBurnVelVec)):mag >= 0 {
                print "burn ended after " + i + " iterations" at (0, 1).
                set burnEnded to true.
            }
            
            // DEBUG
            drawDebugVec(newBurnGeopos, newBurnAlt, burnGeopos, burnAlt, yellow).
            
            // Update variables
            set burnPosVec to newBurnPosVec.
            set burnVelVec to newBurnVelVec.
            set burnGeopos to newBurnGeopos.
            set burnAlt to newBurnAlt.
        }
    }
    
    set calcBurn to false.
    
    wait 0.
}
