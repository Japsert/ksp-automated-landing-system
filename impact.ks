@lazyGlobal off.
clearScreen.
clearVecDraws().

// XYZ vectors relative to the center of the body
vecDraw(v(0,0,0), v(10,0,0), red, "body X", 1, true).
vecDraw(v(0,0,0), v(0,10,0), green, "body Y", 1, true).
vecDraw(v(0,0,0), v(0,0,10), blue, "body Z", 1, true).

// XYZ vectors relative to the surface of the body
vecDraw(v(0,0,0), 10 * v(1,0,0) * ship:up, red, "up X", 1, true).
vecDraw(v(0,0,0), 10 * v(0,1,0) * ship:up, green, "up Y", 1, true).
vecDraw(v(0,0,0), 10 * v(0,0,1) * ship:up, blue, "up Z", 1, true).

// Velocity vector, and separated into vertical and horizontal components
lock velocityVector to ship:velocity:surface.
lock verticalVelocity to vxcl(ship:up:vector, velocityVector).
lock horizontalVelocity to velocityVector - verticalVelocity.
vecDraw(v(0,0,0), { return velocityVector. }, white, "velocity", 1, true).
vecDraw(v(0,0,0), { return verticalVelocity. }, white, "vertical", 1, true).
vecDraw(v(0,0,0), { return horizontalVelocity. }, white, "horizontal", 1, true).

// Every tick, predicts the coordinates of impact (using time intervals of 1s).
until false {
    
    wait 0.
}
