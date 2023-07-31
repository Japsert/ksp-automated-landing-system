clearVecDraws().

set launchpad to ship:geoPosition.
set distanceInterval to 0.002.

set positions to list(
    // list of positions at set intervals just east of the launch pad
    latlng(launchpad:lat, launchpad:lng + 1 * distanceInterval),
    latlng(launchpad:lat, launchpad:lng + 2 * distanceInterval)
).

// to give the vectors different colors, showing that the vectors in the loop
// are drawn on top of each other
function getColor {
    parameter i.
    return choose blue if i = 0 else red.
}

// for every position, draw a vector aiming up and to the south
for i in range(0, positions:length) {
    local i_ is i. // aaah
    vecDraw(
        { return positions[i_]:position. },
        up:vector * 20 - north:vector * 10, getColor(i), "in loop", 1, true
    ).
}

// "manually" draw the vectors, aiming up and to the north
vecDraw(
    { return positions[0]:position. },
    up:vector * 20 + north:vector * 10, getColor(0), "outside loop", 1, true
).
vecDraw(
    { return positions[1]:position. },
    up:vector * 20 + north:vector * 10, getColor(1), "outside loop", 1, true
).

// infinite loop to update the vector's initial positions
until false {
    wait 0.
}
