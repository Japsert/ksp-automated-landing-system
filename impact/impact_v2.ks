@lazyGlobal off.
clearVecDraws().


// Constants
global DELTA_TIME is 1.
global MAX_ITERATIONS is 100.
global DEBUG_LINE is 10.
global VAR_LINE is 20.

// DEBUG
global drawOneTraj is false.
when terminal:input:hasChar then {
    if terminal:input:getChar() = "w" {
        set drawOneTraj to true.
    }
    preserve.
}


//Initial sub-orbital burn to plot impact position over time
//clearScreen. print "Burning until apoapsis >= 50 km...".
//if shouldStage() stage.
//lock throttle to 1.
//lock steering to heading(90, 80, 270).
//when ship:verticalSpeed >= 5 then legs off. 
//wait until ship:verticalSpeed >= 50.
//lock steering to srfPrograde. // gravity turn
//wait until ship:apoapsis >= 50000.
//clearScreen. print"Apoapsis reached 50 km, stopping burn and setting SAS to surface retrograde.".
//lock throttle to 0.
//lock steering to srfRetrograde.
//wait 3. // wait for ship to turn around

// Now coasting until impact. Calculate impact position every tick
local drawnImpactVector is false.
clearScreen.
until false {
    local impact is getImpactPos(
        ship:geoPosition, ship:altitude, ship:velocity:surface
    ).
    
    if impact:isFound {
        local impactPos is impact:position.
        local impactAlt is impact:altitude.
        local iterations is impact:iterations.
        // DEBUG: draw vector to impact position
        set drawnImpactVector to vecDraw(
            ship:position, impactPos:altitudePosition(impactAlt),
            red, "impact", 1, true
        ).
        // DEBUG: print impact lat, lng and alt
        print "Impact found in " + iterations + "/" + MAX_ITERATIONS + " iterations!    " at (0, DEBUG_LINE).
        print "lat: " + impactPos:lat + "    " at (0, DEBUG_LINE+1).
        print "lng: " + impactPos:lng + "    " at (0, DEBUG_LINE+2).
        print "alt: " + impactAlt + "    " at (0, DEBUG_LINE+3).
    } else {
        // DEBUG: remove impact vector and print that no impact was found
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
    local reachedGround is false, maxIterationsReached is false.
    local impactPos is false, impactAlt is false.
    until reachedGround or maxIterationsReached {
        // Save previous values for interpolation
        local prevPos is pos.
        local prevAlt is alt_.
        
        
        // Gravity vector
        local g is body:mu / (body:radius + prevAlt)^2.
        local gravForce is g * ship:mass. // kN
        local gravForceVec is gravForce * -ship:up:vector.
        
        // Drag vector
        local dynamicPressureAtm is ship:dynamicPressure.
        local sqrVelocity is ship:velocity:surface:sqrMagnitude.
        local atmDensity is (2 * dynamicPressureAtm) / sqrVelocity.
        local atmDensityKPa is atmDensity * constant:atmToKPa.
        
        local vel is velVec:mag.
        
        local staticPressure is body:atm:altitudePressure(prevAlt).
        local bulkModulus is staticPressure * body:atm:adiabaticIndex.
        local speedOfSound is sqrt(bulkModulus / atmDensity).
        local machNumber is vel / speedOfSound.
        local CdA is getCdA(machNumber).
        
        local dragForce is 1/2 * atmDensityKPa * sqrVelocity * CdA. // kN
        local dragForceVec is dragForce * -velVec:normalized.
        
        // Total force vector
        local totalForceVec is gravForceVec + dragForceVec. // kN
        
        // Acceleration vector
        local accVec is totalForceVec / ship:mass. // Constant mass, no burn yet
        
        // Update velocity
        set velVec to velVec + accVec * DELTA_TIME.
        
        // Update position, accounting for curvature of the planet
        local positionChangeVec is velVec * DELTA_TIME.
        //if drawOneTraj vecDraw(prevPos:altitudePosition(prevAlt), positionChangeVec, magenta, "pos", 1, true). // DEBUG
        local vecToNewPos is prevPos:altitudePosition(prevAlt) + positionChangeVec.
        set pos to body:geoPositionOf(vecToNewPos).
        set alt_ to body:altitudeOf(vecToNewPos).
        if drawOneTraj vecDraw(ship:position, posNoRotation:altitudePosition(alt_), green, "pos", 1, true). // DEBUG
        if drawOneTraj vecDraw(ship:position, pos:altitudePosition(alt_), cyan, "pos", 1, true). // DEBUG
        
        // DEBUG
        //print "i " + i + " lat " + round(pos:lat, 3) + " lng " + round(pos:lng, 3) + " alt " + round(alt_, 2) at (0, VAR_LINE+i).
        
        // Check if we have impacted
        local posImpactHeight is max(pos:terrainHeight, 0).
        if alt_ <= posImpactHeight {
            set reachedGround to true.
            // Interpolate between pos and prevPos to find precise landing pos
            local prevPosImpactHeight is max(prevPos:terrainHeight, 0).
            local averageImpactHeight is (posImpactHeight + prevPosImpactHeight) / 2.
            local altRatio is (prevAlt - averageImpactHeight) / (prevAlt - alt_).
            local interpolatedPos is latLng(
                prevPos:lat + (pos:lat - prevPos:lat) * altRatio,
                prevPos:lng + (pos:lng - prevPos:lng) * altRatio
            ).
            set impactPos to interpolatedPos.
            set impactAlt to max(impactPos:terrainHeight, 0).
        }
        
        
        // Check if we should give up
        set i to i + 1.
        if i >= MAX_ITERATIONS set maxIterationsReached to true.
    }
    
    set drawOneTraj to false. // DEBUG
    
    return lexicon(
        "isFound", reachedGround,
        "position", impactPos,
        "altitude", impactAlt,
        "iterations", i
    ).
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


/// DEBUG: helper function
function printVars {
    local parameter vars. // lexicon
    
    // Determine the length of the longest variable name.
    local maxVarLength is 0.
    for var in vars:keys {
        local varLength is var:tostring:length.
        if varLength > maxVarLength {
            set maxVarLength to varLength.
        }
    }
    
    from {local i is 0.} until i = vars:length step {set i to i + 1.} do {
        local varName is vars:keys[i].
        local var is vars[varName].
        printAt(
            (varName + ": "):padright(maxVarLength + 2)
            + var + "    ",
            0, VAR_LINE + i
        ).
    }
}
