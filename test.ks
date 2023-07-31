@lazyGlobal off.
clearScreen.
clearVecDraws().

global NUMBER_OF_POSITIONS is 5.
global MODE is 1. // 1 is expected, other is bug (?)

local poss is list(). // list of geopositions
local alts is list(). // list of scalars
// populate the lists
for i in range(0, NUMBER_OF_POSITIONS) {
    poss:add(body:geopositionof(ship:position + north:vector * i * 50)).
    alts:add(poss[i]:terrainheight + 10).
}

// to keep track of the vectors
local drawnVectors is list().

// remainder of the vectors
if MODE = 1 {
    // 
    drawnVectors:add(vecDraw(
        { printAt("drawing " + 0, 0, 0). return poss[0]:altitudeposition(alts[0]). },
        poss[1]:altitudeposition(alts[1]) - poss[0]:altitudeposition(alts[0]),
        white, "0 to 1", 1, true
    )).
    drawnVectors:add(vecDraw(
        { printAt("drawing " + 1, 0, 1). return poss[1]:altitudeposition(alts[1]). },
        poss[2]:altitudeposition(alts[2]) - poss[1]:altitudeposition(alts[1]),
        white, "1 to 2", 1, true
    )).
    drawnVectors:add(vecDraw(
        { printAt("drawing " + 2, 0, 2). return poss[2]:altitudeposition(alts[2]). },
        poss[3]:altitudeposition(alts[3]) - poss[2]:altitudeposition(alts[2]),
        white, "2 to 3", 1, true
    )).
    drawnVectors:add(vecDraw(
        { printAt("drawing " + 3, 0, 3). return poss[3]:altitudeposition(alts[3]). },
        poss[4]:altitudeposition(alts[4]) - poss[3]:altitudeposition(alts[3]),
        white, "3 to 4", 1, true
    )).
} else {
    for i in range (0, NUMBER_OF_POSITIONS-1) {
        local i_ is i. // aaah
        drawnVectors:add(vecDraw(
            {
                printAt("drawing " + i, 0, i).
                return poss[i_]:altitudeposition(alts[i_]).
            },
            // vector from pos i to pos i+1
            poss[i_+1]:altitudeposition(alts[i_+1]) - poss[i_]:altitudeposition(alts[i_]),
            white, i_ + " to " + (i_+1), 1, true
        )).
    }
}

until false {
    wait 0.
}
