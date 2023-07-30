@lazyGlobal off.
clearScreen.
clearVecDraws().

global VAR_LINE is 10.
// Interval between steps in seconds.
global TIME_INTERVAL is 1.

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

local currentPos is ship:geoposition.
local currentAlt is ship:altitude.
local drawnTotalVector is vecdraw().

// Every tick, predicts the coordinates of impact (using time intervals of 1s).
until false {
    set currentPos to ship:geoposition.
    set currentAlt to ship:altitude.
    
    // horizontal vector
    local horizontalVelocity is ship:groundspeed.
    local horizontalDistance is horizontalVelocity * TIME_INTERVAL.
    local horizontalVector is horizontalVelVec:normalized * horizontalDistance.
    
    // vertical vector
    local verticalVelocity is ship:verticalspeed.
    local g is ship:body:mu / (ship:body:radius + ship:altitude)^2.
    local verticalAcceleration is -g.
    local verticalDistance is verticalVelocity * TIME_INTERVAL
        + 1/2 * verticalAcceleration * TIME_INTERVAL^2.
    local verticalVector is up:vector * verticalDistance.
    
    // total vector
    local totalVector is horizontalVector + verticalVector.
    
    set drawnTotalVector to vecdraw(
        { return currentPos:altitudeposition(currentAlt). },
        totalVector, yellow, "total", 1, true
    ).
    
    wait 1.
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
