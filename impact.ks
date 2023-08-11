@lazyGlobal off.
clearScreen.
clearVecDraws().

global VAR_LINE is 10.
global ITERATION_LINE is 20.
printAt("it hd vd alt hv vv rho vel mach CdA dragF dragA", 0, ITERATION_LINE-1).
// Interval between steps in seconds.
global TIME_INTERVAL is 5.
global MAX_ITERATIONS is 10.
global EAST is heading(90, 0).
global LOG_PATH is "0:/logs/impactprediction.log".
if exists(LOG_PATH) deletePath(LOG_PATH).  // Delete log file if it exists
log "time,alt,lat,lng" to LOG_PATH.
global START_TIME is time:seconds.


// XYZ vectors relative to the center of the body
//vecDraw(v(0,0,0), v(10,0,0), red, "body X", 1, true).
//vecDraw(v(0,0,0), v(0,10,0), green, "body Y", 1, true).
//vecDraw(v(0,0,0), v(0,0,10), blue, "body Z", 1, true).

// XYZ vectors relative to the surface of the body
//vecDraw(v(0,0,0), 10 * v(1,0,0) * ship:up, red, "up X", 1, true).
//vecDraw(v(0,0,0), 10 * v(0,1,0) * ship:up, green, "up Y", 1, true).
//vecDraw(v(0,0,0), 10 * v(0,0,1) * ship:up, blue, "up Z", 1, true).

// Velocity vector, and separated into vertical and horizontal components
lock velocityVector to ship:velocity:surface.
//lock verticalVelocityVector to vxcl(ship:up:vector, velocityVector).
lock verticalVelVec to ship:verticalspeed * ship:up:vector. // same as line above
lock horizontalVelVec to velocityVector - verticalVelVec.
vecDraw(v(0,0,0), { return velocityVector. }, white, "velocity", 1, true).
vecDraw(v(0,0,0), { return verticalVelVec. }, white, "vertical", 1, true).
vecDraw(v(0,0,0), { return horizontalVelVec. }, white, "horizontal", 1, true).

local drawnVectorToImpact is vecdraw().
local drawnVectorAtImpact is vecdraw().
local drawnVectorAtImpact2 is vecdraw().
local drawnDragVector is vecdraw().
local impactFound is false.
local prevIterationCount is 0.
local impactPos is 0.

// Every tick, predicts the coordinates of impact (using time intervals of 1s).
until false {
    local startTime is time:seconds.
    // visualization
    local iterationCount is 0.
    
    // loop variables
    local pos is ship:geoposition.
    local alt_ is ship:altitude.
    local horizontalVelocity is ship:groundspeed.
    local verticalVelocity is ship:verticalspeed.
    local normalHorizontalVelVec is horizontalVelVec:normalized. // constant throughout
    until alt_ <= pos:terrainheight or iterationCount > MAX_ITERATIONS {
        // visualization
        set iterationCount to iterationCount + 1.

        // calculate new position and altitude using current position, altitude, and velocity
        local horizontalDistance is horizontalVelocity * TIME_INTERVAL.
        local horizontalVector is normalHorizontalVelVec * horizontalDistance.
        
        local g is ship:body:mu / (ship:body:radius + alt_)^2.
        local verticalAcceleration is -g.
        set verticalVelocity to verticalVelocity + verticalAcceleration * TIME_INTERVAL.
        local verticalDistance is verticalVelocity * TIME_INTERVAL.
        local verticalVector is up:vector * verticalDistance.
        
        // calculate drag vector (in opposite direction of velocity)
        // drag equation: FD = 1/2 * rho * v^2 * Cd * A
        local sqrVelocity is ship:velocity:surface:sqrmagnitude.
        local atmDensity is (2 * ship:dynamicPressure) / sqrVelocity.
        
        local vel is sqrt(horizontalVelocity^2 + verticalVelocity^2).
        
        local staticPressure is body:atm:altitudePressure(alt_).
        local bulkModulus is staticPressure * body:atm:adiabaticindex.
        local speedOfSound is sqrt(bulkModulus / atmDensity).
        local machNumber is vel / speedOfSound.
        local CdA is getCdA(machNumber).
        
        local dragForce is 1/2 * atmDensity * sqrVelocity * CdA.
        local dragAcceleration is dragForce / ship:mass.
        local dragVector is -velocityVector:normalized * dragAcceleration * TIME_INTERVAL.
        set drawnDragVector to vecDraw(
            ship:position, dragVector, blue, "drag", 1, true
        ).
        
        // calculate new velocity using current velocity and drag
        local totalVector is horizontalVector + verticalVector + dragVector.
        
        set pos to body:geopositionof(pos:position + totalVector).
        set alt_ to alt_ + verticalDistance.
        
        printAt(iterationCount
            + " " + round(horizontalDistance)
            + " " + round(verticalDistance)
            + " " + round(alt_)
            + " " + round(horizontalVelocity)
            + " " + round(verticalVelocity)
            + " " + round(atmDensity)
            + " " + round(vel)
            + " " + round(machNumber, 1)
            + " " + round(CdA, 1)
            + " " + round(dragForce, 1)
            + " " + round(dragAcceleration, 1)
            , 0, ITERATION_LINE + iterationCount-1).
    }
    set impactFound to not (iterationCount > MAX_ITERATIONS).
    if impactFound {
        if iterationCount <> prevIterationCount {
            set impactPos to pos.
            printAt("iterations until impact: " + iterationCount + "  ", 0, 10).
            printAt("impact pos " + round(impactPos:lat, 5) + ", " + round(impactPos:lng, 5) + "  ", 0, 11).
            // draw vector from ship to impact point
            set drawnVectorToImpact to vecDraw(
                ship:position,
                { return pos:position. },
                red, "impact", 1, true
            ).
            set drawnVectorAtImpact to vecDraw(
                { return impactPos:position + north:vector * 10 + up:vector * 1. },
                -north:vector * 20,
                red, "", 1, true
            ).
            set drawnVectorAtImpact2 to vecDraw(
                { return impactPos:position + EAST:vector * 10 + up:vector * 1. },
                -EAST:vector * 20,
                red, "", 1, true
            ).
            log (time:seconds - START_TIME) + "," + ship:altitude + "," + impactPos:lat + "," + impactPos:lng to LOG_PATH.
        }
    } else {
        set drawnVectorToImpact to vecDraw().
        set drawnVectorAtImpact to vecDraw().
        set drawnVectorAtImpact2 to vecDraw().
    }
    set prevIterationCount to iterationCount.
    
    printAt("iteration took " + round(time:seconds - startTime, 2) + "ms   ", 0, 12).
    
    wait 0.
}

// Look up value of drag coefficient * facing area for a given Mach number.
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

// Helper function
function printVariables {
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
            + (choose round(var, 2) if var:istype("Scalar") else var) + "    ",
            0, VAR_LINE + i
        ).
    }
}
