// Impact Prediction Library
// by Japsert, 2023

@lazyGlobal off.

// Impact predictor class
function ImpactPredictor {
    
    // Constructor
    local dT is 2.
    local burnDT is 1.
    local parameter maxIterations is 250.
    local parameter maxBurnIterations is 100.
    local bodyRotationPerStep is
        2 * constant:pi / body:rotationPeriod * constant:radToDeg * dT.
    local mu is body:mu.
    local atm is body:atm.
    local atmMolarMass is atm:molarMass.
    local atmAdbIdx is atm:adiabaticIndex.
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
        print "ERROR: Temperature lookup failed. Altitude: " + alt_ + "m".
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
    
    function getAcc { // TODO: optimize
        local parameter posVec.
        local parameter velVec. // orbital velocity
        
        // Convert non-inertial velocity to inertial velocity
        local velVecSrf is velVec - vCrs(body:angularVel, posVec - body:position).
        
        // Gravity
        local centerToPosVec is posVec - body:position.
        local alt_ is centerToPosVec:mag - body:radius.
        
        local g is mu / centerToPosVec:sqrMagnitude.
        local gravAccVec is g * -centerToPosVec:normalized.
        
        // Drag
        local staticPressure is atm:altitudePressure(alt_).
        local atmDensityAtm is
            (staticPressure * atmMolarMass) / (idealGas * lookUpTemp(alt_)).
        local atmDensityKPa is atmDensityAtm * atmToKPa.
        
        local CdA is lookUpCdA(
            velVecSrf:mag / sqrt(staticPressure * atmAdbIdx / atmDensityAtm)
        ).
        
        local dragAcc is 0.5 * atmDensityKPa * velVecSrf:sqrMagnitude * CdA.
        local dragAccVec is dragAcc * -velVecSrf:normalized.
        
        return gravAccVec + dragAccVec.
    }

    function getImpactPos {
        parameter initialPosVec.
        parameter initialVelVec.
        
        local posVec is initialPosVec.
        local velVec is initialVelVec.
        local alt_ is body:altitudeOf(initialPosVec).
        local geopos is body:geopositionOf(initialPosVec).
        
        local i is 0.
        local reachedGround is false.
        local maxIterationsReached is false.
        
        local impactGeopos is false.
        local impactAlt is false.
        
        until reachedGround or maxIterationsReached {
            set i to i + 1.
            
            // Update position and velocity
            // RK1
            local accVec is getAcc(posVec, velVec).
            local newPosVec is posVec + velVec * dT + 0.5 * accVec * dT^2.
            local newVelVec is velVec + accVec * dT.
            
            // RK2
            
            
            // RK4
            
            
            
            // Convert to geocoordinates/altitude, and correct for body rotation
            local newGeopos is body:geopositionOf(newPosVec).
            local newAlt is body:altitudeof(newPosVec).
            set newGeopos to
                latLng(newGeopos:lat, newGeopos:lng - bodyRotationPerStep * i).
            
            // Check for impact
            if newAlt < max(newGeopos:terrainHeight, 0) {
                set reachedGround to true.
                // Interpolate impact position
                local newGeoposSurfaceAlt is max(newGeopos:terrainHeight, 0).
                local oldGeoposSurfaceAlt is max(geopos:terrainHeight, 0).
                local averageSurfaceAlt is
                    (oldGeoposSurfaceAlt + newGeoposSurfaceAlt) / 2.
                local altRatio is (alt_ - averageSurfaceAlt) / (alt_ - newAlt).
                set impactGeopos to latLng(
                    geopos:lat + (newGeopos:lat - geopos:lat) * altRatio,
                    geopos:lng + (newGeopos:lng - geopos:lng) * altRatio
                ).
                set impactAlt to max(impactGeopos:terrainHeight, 0).
            }
            
            // Check for max iterations
            if i >= maxIterations set maxIterationsReached to true.
            
            // Update variables
            set posVec to newPosVec.
            set velVec to newVelVec.
            set geopos to newGeopos.
            set alt_ to newAlt.
        }
        
        return lexicon(
            "isFound", reachedGround,
            "geoposition", impactGeopos,
            "altitude", impactAlt
        ).
    }
    
    function getBurnAcc { // TODO: optimize
        local parameter posVec.
        local parameter velVec. // orbital velocity
        
        // Convert non-inertial velocity to inertial velocity
        local velVecSrf is velVec - vCrs(body:angularVel, posVec - body:position).
        
        // Gravity
        local centerToPosVec is posVec - body:position.
        local alt_ is centerToPosVec:mag - body:radius.
        
        local g is mu / centerToPosVec:sqrMagnitude.
        local gravAccVec is g * -centerToPosVec:normalized.
        
        // Drag
        local staticPressure is atm:altitudePressure(alt_).
        local atmDensityAtm is
            (staticPressure * atmMolarMass) / (idealGas * lookUpTemp(alt_)).
        local atmDensityKPa is atmDensityAtm * atmToKPa.
        
        local CdA is lookUpCdA(
            velVecSrf:mag / sqrt(staticPressure * atmAdbIdx / atmDensityAtm)
        ).
        
        local dragAcc is 
            0.5 * atmDensityKPa * velVecSrf:sqrMagnitude * CdA.
        local dragAccVec is dragAcc * -velVecSrf:normalized.
        
        // Thrust
        local thrustAcc is engine:possibleThrustAt(staticPressure) / mass.
        local thrustAccVec is thrustAcc * -velVecSrf:normalized.
        
        return gravAccVec + dragAccVec + thrustAccVec.
    }
    
    function getLandingPos {
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
        
        until landed or maxIterationsReached {
            set i to i + 1.
            
            // Update position and velocity
            // RK1
            local accVec is getAcc(posVec, velVec).
            local newPosVec is posVec + velVec * dT + 0.5 * accVec * dT^2.
            local newVelVec is velVec + accVec * dT.
            
            // RK2
            
            
            // RK4
            
            
            local shouldCalculateLandingBurn is true.
            // determine if we should calculate the landing burn
            if shouldCalculateLandingBurn { // TODO
                local burnPosVec is newPosVec.
                local burnVelVec is newVelVec.
                
                local j is 0.
                local burnEnded is false.
                local maxBurnIterationsReached is false.
                
                until burnEnded or maxBurnIterationsReached {
                    set j to j + 1.
                    
                    // Update position and velocity (RK1)
                    local burnAccVec is getBurnAcc(burnPosVec, burnVelVec).
                    local newBurnPosVec is burnPosVec + burnVelVec * burnDT
                        + 0.5 * burnAccVec * burnDT^2.
                    local newBurnVelVec is burnVelVec + burnAccVec * burnDT.
                    
                    // Check for burn end
                    if newBurnVelVec:mag >= burnVelVec:mag {
                        set burnEnded to true.
                        local newBurnGeopos is body:geopositionOf(newBurnPosVec).
                        local newBurnAlt is body:altitudeOf(newBurnPosVec).
                        set newBurnGeopos to latLng(
                            newBurnGeopos:lat,
                            newBurnGeopos:lng - bodyRotationPerStep * j
                        ).
                        // Check for landing
                        if newBurnAlt <= max(newBurnGeopos:terrainHeight, 0) {
                            set landed to true.
                            // can't be bothered, just choose the new one
                            set landingGeopos to newBurnGeopos.
                            set landingAlt to newBurnAlt.
                            set burnStartAlt to body:altitudeOf(newPosVec).
                        }
                    }
                    
                    // Check for max iterations
                    if j >= maxBurnIterations set maxBurnIterationsReached to true.
                    
                    // Update variables
                    set burnPosVec to newBurnPosVec.
                    set burnVelVec to newBurnVelVec.
                }
            }
            
            // Check for max iterations
            if i >= maxIterations set maxIterationsReached to true.

            // Update variables
            set posVec to newPosVec.
            set velVec to newVelVec.
        }
        
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
    