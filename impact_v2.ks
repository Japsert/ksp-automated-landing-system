@lazyGlobal off.

// Constants
global ATM_TO_PA is constant:atmToKPa * 1000.
global DELTA_TIME is 1.
global MAX_ITERATIONS is 50.

function getImpactPos {
    // Initial values
    local parameter initialPos.
    local parameter initialAlt.
    local parameter initialVelVec.
    
    // Loop variables
    local pos is initialPos.
    local alt_ is initialAlt.
    local velVec is initialVelVec.
    
    local i is 0.
    local reachedGroud is false, maxIterationsReached is false.
    local impactPos is false, impactAlt is false.
    until reachedGround or maxIterationsReached {
        // Save previous values for interpolation
        local prevPos is pos.
        local prevAlt is alt_.
        
        
        // Gravity vector
        local g is body:mu / (body:radius + prevAlt)^2.
        local gForceVec is g * -ship:up:vector.
        
        // Drag vector
        local dynamicPressureAtm is ship:dynamicPressure.
        local sqrVelocity is ship:velocity:surface:sqrMagnitude.
        local atmDensity is (2 * dynamicPressureAtm) / sqrVelocity.
        local atmDensityPa is atmDensity * ATM_TO_PA.
        
        local vel is velVec:mag.
        
        local staticPressure is body:atm:altitudePressure(prevAlt).
        local bulkModulus is staticPressure * body:atm:adiabaticIndex.
        local speedOfSound is sqrt(bulkModulus / atmDensity).
        local machNumber is vel / speedOfSound.
        local CdA is getCdA(machNumber).
        
        local dragForce is 1/2 * atmDensityPa * sqrVelocity * CdA. // N
        local dragForceVec is dragForce * -velVec:normalized.
        
        // Total force vector
        local totalForceVec is gForceVec + dragForceVec.
        
        // Acceleration vector
        local accVec is totalForceVec / ship:mass. // Constant mass, no burn yet
        
        // Update velocity
        set velVec to prevVel + accVec * DELTA_TIME.
        
        // Update position, accounting for curvature of the planet
        local positionChangeVec is velVec * DELTA_TIME.
        set pos to body:geoPositionOf(pos:position + positionChangeVec).
        set alt_ to body:altitudeOf(pos:position + positionChangeVec).
        
        
        // Check if we have impacted
        if alt_ <= pos:terrainHeight {
            set reachedGround to true.
            // Interpolate between pos and prevPos to find precise landing pos
            local ratio is prevAlt / (prevAlt + alt_).
            local interpolatedPos is latLng(
                prevPos:lat + (pos:lat - prevPos:lat) * ratio,
                prevPos:lng + (pos:lng - prevPos:lng) * ratio
            ).
            set impactPos to interpolatedPos.
            set impactAlt to impactPos:terrainheight.
        }
        
        
        // Check if we should give up
        set i to i + 1.
        if i >= MAX_ITERATIONS set maxIterationsReached to true.
    }
    
    return list(impactPos, impactAlt).
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
