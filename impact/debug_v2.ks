@lazyGlobal off.
clearScreen.
clearVecDraws().

local parameter doInitialBurn is false.

// Time step in seconds
global DT is 1.
print "dT: " + DT + "s" at (0, 0).

// Draw trajectory vectors when 'w' is pressed
local drawDebugVectors is false.
when terminal:input:haschar then {
    if terminal:input:getchar() = "w" {
        set drawDebugVectors to true.
    }
    preserve.
}

if doInitialBurn {
    stage.
    lock throttle to 1.
    lock steering to heading(90, 80, 270).
    wait until ship:altitude > 1000.
    lock throttle to 0.

    // Wait 5 ticks to make sure throttle delay doesn't influence acceleration
    wait 0.1.
    // Draw debug vectors for the first loop
    set drawDebugVectors to true.
}


// Draws a vector from pos to pos + vec
function drawDebugVec {
    local parameter geopos.
    local parameter alt_.
    local parameter vecToNewPos.
    local parameter i.
    
    vecDraw(
        { return geopos:altitudePosition(alt_). }, vecToNewPos,
        red, i, 1, true
    ).
}

until false {
    local posVec is ship:position.
    local velVec is ship:velocity:orbit.
    local correctedGeopos is ship:geoposition.
    local i is 0.
    local reachedGround is false.
    local drawDebugVectorsThisIteration is drawDebugVectors. // DEBUG
    until reachedGround {
        set i to i+1.
        
        // Calculate altitude
        local centerToPosVec is (posVec - body:position).
        local altFromCenter is centerToPosVec:mag.
        local alt_ is altFromCenter - body:radius.
        
        // Determine acceleration at altitude
        local g is (body:mu)/(altFromCenter)^2.
        local gravAccVec is -centerToPosVec:normalized * g.
        local accVec is gravAccVec.
        
        // Calculate vector pointing to next position (starting from current
        // position vector)
        local positionChangeVec is velVec * DT + 0.5 * accVec * DT^2.
        
        // Add this vector to the position vector
        local newPosVec is posVec + positionChangeVec.
        
        // Calculate new velocity vector
        local newVelVec is velVec + accVec * DT.
        
        // Convert new position vector (starting from ship) to
        // geocoordinates/altitude
        local newGeopos is body:geopositionOf(newPosVec).
        local newAlt is body:altitudeOf(newPosVec).
        
        // Correct geocoordinates for body rotation
        local bodyRotationPerStep is // should be precomputed
            body:angularVel:mag * constant:radToDeg * DT.
        local bodyRotationSinceStart is bodyRotationPerStep * i.
        local correctedNewGeopos is 
            latLng(newGeopos:lat, newGeopos:lng - bodyRotationSinceStart).
        
        // Check if we reached the ground
        if newAlt <= max(correctedNewGeopos:terrainHeight, 0)
            set reachedGround to true.
        
        // DEBUG: Draw debug vector
        // Draw vector from rotation corrected geocoordinates/altitude from
        // previous iteration to rotation corrected geocoordinates/altitude from
        // current iteration
        local srfPosVec is correctedGeopos:altitudePosition(alt_).
        local newSrfPosVec is correctedNewGeopos:altitudePosition(newAlt).
        local vecToNewPos is newSrfPosVec - srfPosVec.
        if drawDebugVectorsThisIteration
            drawDebugVec(correctedGeopos, alt_, vecToNewPos, i).
        
        // Set the position vector (starting from ship) and the velocity vector
        // for the next iteration
        set posVec to newPosVec.
        set velVec to newVelVec.
        set correctedGeopos to correctedNewGeopos. // DEBUG
    }
    // Finished first loop, stop drawing debug vectors
    set drawDebugVectors to false. // DEBUG
    
    if reachedGround
        print "Reached ground after " + i + " iterations" at (0, 1).
    
    wait 0.
}
