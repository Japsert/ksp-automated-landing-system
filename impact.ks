@lazyGlobal off.
clearScreen.
clearVecDraws().

global VAR_LINE is 10.
// Interval between steps in seconds.
global TIME_INTERVAL is 1.
global MAX_ITERATIONS is 30.

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

local drawnImpactVector is vecdraw().
local drawnTrajectoryVectors is list().
local poss is list().
local alts is list().
local impactFound is false.

for i in range(0, MAX_ITERATIONS) {
    local i_ is i.
    drawnTrajectoryVectors:add(vecdraw(
        {
            return choose v(0,0,0) if i_ >= poss:length-1 or not impactFound else
                poss[i_]:altitudeposition(alts[i_]).
        },
        { 
            return choose v(0,0,0) if i_ >= poss:length-1 or not impactFound else
                poss[i_+1]:altitudeposition(alts[i_+1]) - poss[i_]:altitudeposition(alts[i_]).
        },
        white, i_, 1, true
    )).
}

// Every tick, predicts the coordinates of impact (using time intervals of 1s).
until false {
    local startTime is time:seconds.
    // visualization
    local iterationCount is 0.
    set poss to list().
    set alts to list().
    
    // loop variables
    local newPos is ship:geoposition.
    local newAlt is ship:altitude.
    local horizontalVelocity is ship:groundspeed.
    local newVerticalVelocity is ship:verticalspeed.
    local normalHorizontalVelVec is horizontalVelVec:normalized. // constant throughout
    until newAlt <= newPos:terrainheight or iterationCount > MAX_ITERATIONS {
        // visualization
        set iterationCount to iterationCount + 1.
        poss:add(newPos).
        alts:add(newAlt).

        // calculate new position and altitude using current position, altitude, and velocity
        local newHorizontalDistance is horizontalVelocity * TIME_INTERVAL.
        local newHorizontalVector is normalHorizontalVelVec * newHorizontalDistance.
        
        local newG is ship:body:mu / (ship:body:radius + newAlt)^2.
        local newVerticalAcceleration is -newG.
        set newVerticalVelocity to newVerticalVelocity + newVerticalAcceleration * TIME_INTERVAL.
        local newVerticalDistance is newVerticalVelocity * TIME_INTERVAL.
        local newVerticalVector is up:vector * newVerticalDistance.
        
        local newTotalVector is newHorizontalVector + newVerticalVector.
        
        set newPos to body:geopositionof(newPos:position + newTotalVector).
        set newAlt to newAlt + newVerticalDistance.
    }
    set impactFound to not (iterationCount > MAX_ITERATIONS).
    if impactFound {
        printAt("iterations until impact: " + iterationCount + "  ", 0, 10).
        printAt("impact pos " + round(newPos:lat, 2) + ", " + round(newPos:lng, 2)
        + ", alt " + round(newAlt, 2) + "  ", 0, 11).
        // draw vector from ship to impact point
        set drawnImpactVector to vecDraw(
            ship:position, newPos:altitudeposition(newAlt),
            red, "impact", 1, true
        ).
    }
    
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
