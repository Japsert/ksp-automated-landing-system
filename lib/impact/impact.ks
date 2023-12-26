// Impact Prediction Library
// by Japsert, 2023

@lazyGlobal off.

// DEBUG
local drawImpactDebugVecs is false.
local drawLandingDebugVecs is false.
when terminal:input:hasChar then {
    local c is terminal:input:getChar().
    if c = "q" {
        set drawImpactDebugVecs to true.
    } else if c = "w" {
        set drawLandingDebugVecs to true.
    } else if c = "c" {
        clearVecDraws().
    }
    preserve.
}

// Impact predictor class
function ImpactPredictor {
    
    local targetIterations is 25.
    local dT is 10.
    local halfDT is dT / 2.
    local sixthDT is dT / 6.
    local burnDT is 2.
    local parameter maxIterations is 100.
    local parameter maxBurnIterations is 30.
    local bodyRotationPerSecond is
        2 * constant:pi / body:rotationPeriod * constant:radToDeg.
    local bodyRotationPerStep is bodyRotationPerSecond * dT.
    local bodyRotationPerBurnStep is bodyRotationPerSecond * burnDT.
    local mu is body:mu.
    local atm is body:atm.
    local atmMolarMass is atm:molarMass.
    local atmAdbIdx is atm:adiabaticIndex.
    local atmHeight is atm:height.
    local idealGas is constant:idealGas.
    local atmToKPa is constant:atmToKPa.
    local engine is ship:engines[0].
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
    
    function lookUpTemp {
        local parameter alt_.
        
        for segment in tempLookupTable {
            if alt_ >= segment:start and alt_ < segment:end {
              local returnValue is 0.
              if segment:hasKey("x^0") {
                set returnValue to returnValue + segment["x^0"].
                if segment:hasKey("x^1") {
                  set returnValue to returnValue + segment["x^1"] * alt_.
                  if segment:hasKey("x^2") {
                    set returnValue to returnValue + segment["x^2"] * alt_^2.
                    if segment:hasKey("x^3") {
                      set returnValue to returnValue + segment["x^3"] * alt_^3.
                    }
                  }
                }
              }
              return returnValue.
            }
        }
        // DEBUG
        if alt_ < 0 print "ERROR: Temperature lookup failed. Altitude: " + alt_ + "m".
        return 0.
    }
    
    function lookUpCdA {
        local parameter mach.
        
        for segment in cdaLookupTable {
            if mach >= segment:start and mach < segment:end {
              local returnValue is 0.
              if segment:hasKey("x^0") {
                set returnValue to returnValue + segment["x^0"].
                if segment:hasKey("x^1") {
                  set returnValue to returnValue + segment["x^1"] * mach.
                  if segment:hasKey("x^2") {
                    set returnValue to returnValue + segment["x^2"] * mach^2.
                    if segment:hasKey("x^3") {
                      set returnValue to returnValue + segment["x^3"] * mach^3.
                    }
                  }
                }
              }
              return returnValue.
            }
        }
        return 0.
    }
    
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
        
        //if alt_ >= atmHeight or alt_ < 0 return gravAccVec.
        
        // Drag
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

    function getImpactPos {
        parameter initialPosVec.
        parameter initialVelVec. // orbital velocity
        
        local posVec is initialPosVec.
        local velVec is initialVelVec.
        local geopos is body:geopositionOf(initialPosVec).
        local alt_ is body:altitudeOf(initialPosVec).
        
        local i is 0.
        local reachedSurface is false.
        local maxIterationsReached is false.
        
        local impactGeopos is false.
        local impactAlt is false.
        
        // DEBUG
        local drawDebugVectorsThisIteration is drawImpactDebugVecs.
        
        until reachedSurface or maxIterationsReached {
            set i to i + 1.
            
            // Update position and velocity using RK4
            local k1VelVec is velVec.
            local k1AccVec is getAccVec(posVec, k1VelVec).
            local k2VelVec is velVec + k1AccVec * halfDT.
            local k2AccVec is getAccVec(posVec + k1VelVec * halfDT, k2VelVec).
            local k3VelVec is velVec + k2AccVec * halfDT.
            local k3AccVec is getAccVec(posVec + k2VelVec * halfDT, k3VelVec).
            local k4VelVec is velVec + k3AccVec * dT.
            local k4AccVec is getAccVec(posVec + k3VelVec * dT, k4VelVec).
            
            local newPosVec is
                posVec + sixthDT * (k1VelVec + 2 * k2VelVec + 2 * k3VelVec + k4VelVec).
            local newVelVec is
                velVec + sixthDT * (k1AccVec + 2 * k2AccVec + 2 * k3AccVec + k4AccVec).
            
            // Convert to geocoordinates/altitude, and correct for body rotation
            local newGeopos is body:geopositionOf(newPosVec).
            local newAlt is body:altitudeof(newPosVec).
            set newGeopos to latLng(newGeopos:lat, newGeopos:lng - bodyRotationPerStep * i).
            
            // Check for impact
            if newAlt < max(newGeopos:terrainHeight, 0) {
                set reachedSurface to true.
                // Interpolate impact position
                local newGeoposSurfaceAlt is max(newGeopos:terrainHeight, 0).
                local oldGeoposSurfaceAlt is max(geopos:terrainHeight, 0).
                local averageSurfaceAlt is (oldGeoposSurfaceAlt + newGeoposSurfaceAlt) / 2.
                local altRatio is (alt_ - averageSurfaceAlt) / (alt_ - newAlt).
                set impactGeopos to latLng(
                    geopos:lat + (newGeopos:lat - geopos:lat) * altRatio,
                    geopos:lng + (newGeopos:lng - geopos:lng) * altRatio
                ).
                set impactAlt to max(impactGeopos:terrainHeight, 0).
                set i to i + altRatio.
            }
            
            // Check for max iterations
            if i >= maxIterations
                set maxIterationsReached to true.
            
            // DEBUG
            if drawDebugVectorsThisIteration
                drawDebugVec(newGeopos, newAlt, geopos, alt_, red, i).
            
            // Update variables
            set posVec to newPosVec.
            set velVec to newVelVec.
            set geopos to newGeopos.
            set alt_ to newAlt.
        }
        
        // Update time step to reach target number of iterations
        set dT to dT * (i / targetIterations).
        if dT < 1
            set dT to 1.
        else if dT > 60
            set dT to 60.
        set bodyRotationPerStep to bodyRotationPerSecond * dT.
        set halfDT to dT / 2.
        set sixthDT to dT / 6.
        
        // DEBUG
        set drawImpactDebugVecs to false.
        
        return lexicon(
            "isFound", reachedSurface,
            "geoposition", impactGeopos,
            "altitude", impactAlt
        ).
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
        local parameter newgeopos.
        local parameter newalt.
        local parameter geopos.
        local parameter alt_.
        local parameter color.
        local parameter i.
        
        local vecToNewPos is newgeopos:altitudePosition(newalt).
        local vecToOldPos is geopos:altitudePosition(alt_).
        local vec is vecToNewPos - vecToOldPos.
        vecDraw(
            { return geopos:altitudePosition(alt_). },
            vec, color, i, 1, true
        ).
    }
    
    function getLandingPos { // TODO: not updated
        local parameter initialPosVec.
        local parameter initialVelVec.
        
        local posVec is initialPosVec.
        local velVec is initialVelVec.
        
        local i is 0.
        local landed is false.
        local maxIterationsReached is false.
        
        local landingGeopos is false.
        local landingAlt is false.
        local burnStartAlt is false.
        
        // DEBUG
        local drawDebugVectorsThisIteration is drawLandingDebugVecs.
        
        until landed or maxIterationsReached {
            set i to i + 1.
            
            // Update position and velocity using RK4
            local k1VelVec is velVec.
            local k1AccVec is getAccVec(posVec, k1VelVec).
            local k2VelVec is velVec + k1AccVec * halfDT.
            local k2AccVec is getAccVec(posVec + k1VelVec * halfDT, k2VelVec).
            local k3VelVec is velVec + k2AccVec * halfDT.
            local k3AccVec is getAccVec(posVec + k2VelVec * halfDT, k3VelVec).
            local k4VelVec is velVec + k3AccVec * dT.
            local k4AccVec is getAccVec(posVec + k3VelVec * dT, k4VelVec).
            
            local newPosVec is
                posVec + sixthDT * (k1VelVec + 2 * k2VelVec + 2 * k3VelVec + k4VelVec).
            local newVelVec is
                velVec + sixthDT * (k1AccVec + 2 * k2AccVec + 2 * k3AccVec + k4AccVec).
            
            // determine if we should calculate the landing burn
            local burnPosVec is newPosVec.
            local burnVelVec is newVelVec.
            local burnAlt is body:altitudeOf(burnPosVec).
            local shouldCalculateLandingBurn is burnAlt <= 40000. // TODO
            if shouldCalculateLandingBurn {
                // Convert to geopos and correct for body rotation
                local burnGeopos is body:geopositionOf(burnPosVec).
                set burnGeopos to latLng(burnGeopos:lat, burnGeopos:lng - bodyRotationPerStep * i).
                
                local j is 0.
                local burnEnded is false.
                local maxBurnIterationsReached is false.
                
                until burnEnded or maxBurnIterationsReached {
                    set j to j + 1.
                    
                    // Update position and velocity using Euler's method
                    local burnAccVec is getBurnAccVec(burnPosVec, burnVelVec).
                    local newBurnPosVec is
                        burnPosVec + burnVelVec * burnDT + 0.5 * burnAccVec * burnDT^2.
                    local newBurnVelVec is burnVelVec + burnAccVec * burnDT.
                    
                    // Convert to geopos/alt and correct for body rotation
                    local newBurnGeopos is body:geopositionOf(newBurnPosVec).
                    set newBurnGeopos to latLng(newBurnGeopos:lat,
                        newBurnGeopos:lng - bodyRotationPerStep * i - bodyRotationPerBurnStep * j).
                    local newBurnAlt is body:altitudeOf(newBurnPosVec).
                    
                    // If we are below the surface, interpolate to find exact landing position
                    if newBurnAlt <= max(newBurnGeopos:terrainHeight, 0) {
                        set burnEnded to true.
                        set landed to true.
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
                    if newBurnVelVec:mag >= burnVelVec:mag
                    // or (newBurnVelVec - // TODO: fix
                        //vectorExclude(newBurnPosVec - body:position, newBurnVelVec)):mag >= 0
                        set burnEnded to true.
                    
                    // Check for max iterations
                    if j >= maxBurnIterations set maxBurnIterationsReached to true.
                    
                    // DEBUG
                    if drawDebugVectorsThisIteration drawDebugVec(
                        newBurnGeopos, newBurnAlt, burnGeopos, burnAlt,
                        yellow, j
                    ).
                    
                    // Update variables
                    set burnPosVec to newBurnPosVec.
                    set burnVelVec to newBurnVelVec.
                    set burnGeopos to newBurnGeopos. // DEBUG
                    set burnAlt to newBurnAlt. // DEBUG
                }
            }
            
            // We don't have to check for impact, that's done in the burn loop
            
            // Check for max iterations
            if i >= maxIterations set maxIterationsReached to true.

            // Update variables
            set posVec to newPosVec.
            set velVec to newVelVec.
        }
        
        // DEBUG
        set drawLandingDebugVecs to false.

        return lexicon(
            "isFound", landed,
            "geoposition", landingGeopos,
            "altitude", landingAlt,
            "startAltitude", burnStartAlt
        ).
    }
    
    return lexicon(
        "getImpactPos", getImpactPos@,
        "getLandingPos", getLandingPos@
    ).
}
    