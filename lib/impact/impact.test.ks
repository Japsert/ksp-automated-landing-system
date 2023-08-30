@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/impact/impact.ks").

local impactPredictor is ImpactPredictor().

until false {
    // impact prediction
    local startTime is time:seconds.
    local startOpcodes is opcodesLeft.

    local impact is impactPredictor:getImpactPos(
        ship:position, ship:velocity:orbit
    ).

    local endOpcodes is opcodesLeft.
    local ticksElapsed is round((time:seconds - startTime) / 0.02).
    local opcodesElapsed is ticksElapsed * config:IPU + startOpcodes - endOpcodes.

    print "impact at lat "
        + round(impact:geoposition:lat, 6) + " lon "
        + round(impact:geoposition:lng, 6) + " alt "
        + round(impact:altitude, 2) + "m"
        at (0, 10).
    print "impact prediction took " + ticksElapsed + " ticks (~" + ticksElapsed/50 + "s) or " + opcodesElapsed + " opcodes.            " at (0, 11).
    
    // landing prediction
    local startTime is time:seconds.
    local startOpcodes is opcodesLeft.
    
    local landing is impactPredictor:getLandingPos(
        ship:position, ship:velocity:orbit
    ).
    
    local endOpcodes is opcodesLeft.
    local ticksElapsed is round((time:seconds - startTime) / 0.02).
    local opcodesElapsed is ticksElapsed * config:IPU + startOpcodes - endOpcodes.
    
    print "landing at lat "
        + round(landing:geoposition:lat, 6) + " lon "
        + round(landing:geoposition:lng, 6) + " alt "
        + round(landing:altitude, 2) + "m (start alt "
        + round(landing:startAltitude) + "m)"
        at (0, 13).
    print "landing prediction took " + ticksElapsed + " ticks (~" + ticksElapsed/50 + "s) or " + opcodesElapsed + " opcodes.            " at (0, 14).
}
