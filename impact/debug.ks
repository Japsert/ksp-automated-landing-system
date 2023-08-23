@lazyGlobal off.
clearScreen.
clearVecDraws().

local parameter doInitialBurn is false.

// Time step in seconds
global DT is 1.
print "dT: " + DT + "s" at (0, 0).

local drawDebugVectors is false.
when terminal:input:haschar then {
    if terminal:input:getchar() = "w" {
        set drawDebugVectors to true.
    }
}

// Draws a vector from pos to pos + vec
function drawDebugVec {
    local parameter pos.
    local parameter alt_.
    local parameter vecToNewPos.
    local parameter i.
    
    vecDraw(
        { return pos:altitudePosition(alt_). }, vecToNewPos,
        red, i, 1, true
    ).
}

// Initial burn
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

until false {
    local pos is ship:geoPosition.
    local alt_ is ship:altitude.
    local velVec is ship:velocity:surface.
    
    local i is 1.
    until alt_ <= pos:terrainheight {
        // Gravitational acceleration at current pos/alt
        local g is body:mu / (body:radius + alt_)^2.
        local gravForce is g * ship:mass. // kN
        local vecToCenterAtPos is body:position - pos:position.
        local gravForceVec is gravForce * vecToCenterAtPos:normalized.
        local accVec is gravForceVec / ship:mass.
        
        // Vector from this iteration's pos/alt to next iteration's pos/alt
        local positionChangeVec is velVec * DT + 1/2 * accVec * DT^2.
        // Vector from ship to next iteration's pos/alt, to calculate
        // newPos and newAlt below
        local vecToNewPos is pos:altitudePosition(alt_) + positionChangeVec.
        
        // Update position, altitude and velocity, accounting for the
        // curvature of Kerbin
        local newPos is body:geoPositionOf(vecToNewPos).
        local newAlt is body:altitudeOf(vecToNewPos).
        local newVelVec is velVec + accVec * DT.
        
        if drawDebugVectors drawDebugVec(pos, alt_, positionChangeVec, i).
        
        set i to i + 1.
        // Set variables for next iteration
        set pos to newPos.
        set alt_ to newAlt.
        set velVec to newVelVec.
    }
    // Finished first loop, stop drawing debug vectors
    set drawDebugVectors to false.
    
    print "reached ground in " + i + " iterations" at (0, 1).
    
    wait 0.
}
