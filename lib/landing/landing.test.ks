@lazyGlobal off.
clearVecDraws().

lock posVec to latlng(-0.097, -74.55):altitudeposition(80).
lock velVec to v(-10,0,0).
lock upVec to 15 * (posVec - body:position):normalized.

vecDraw({return posVec.}, velVec, blue, "a", 1, true).
vecDraw({return posVec.}, upVec, red, "up", 1, true).

lock exclVec to vectorExclude(upVec, velVec).
lock exclVec2 to vectorExclude(exclVec, velVec).

lock projVec to vDot(velVec, upVec:normalized) * upVec:normalized.

vecDraw({return posVec.}, projVec, green, "excl", 1, true).

wait until false.
