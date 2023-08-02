@lazyGlobal off.
clearScreen.
clearVecDraws().

global VAR_LINE is 10.
// Interval between steps in seconds.
global TIME_INTERVAL is .5.
global MAX_ITERATIONS is 100.
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
        
        local totalVector is horizontalVector + verticalVector.
        
        set pos to body:geopositionof(pos:position + totalVector).
        set alt_ to alt_ + verticalDistance.
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
