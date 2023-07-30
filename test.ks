@lazyGlobal off.
clearScreen.
clearVecDraws().

//global LATLNG_POS is latlng(-0.0905587300633405, -74.5768403740745).

//local drawnVector is v(0,0,0).
//until false {
//    // construct a vector to a latlng
//    local vectorToLatLng is LATLNG_POS:position.
//    // draw vector from ship
//    set drawnVector to vecDraw(vectorToLatLng, up:vector * 10, red, "vectorToLatLng", 1, true).
//    wait 0.
//}

local prevPos is ship:geoposition.
local prevAlt is ship:altitude.
local drawnVector is vecdraw().

when true then {
    // construct a vector to previous position
    local vectorToPrevPos is prevPos:altitudeposition(prevAlt).
    // draw vector from prevPos, to 10 meters up from there
    set drawnVector to vecDraw(
        vectorToPrevPos, up:vector * 10, red, "pog", 1, true
    ).
    preserve.
}

until false {
    set prevPos to ship:geoposition.
    set prevAlt to ship:altitude.
    wait 1.
}
