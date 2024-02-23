@lazyGlobal off.
clearScreen.
clearVecDraws().

runOncePath("0:/lib/impact/impact.ks").

local impactPredictor is ImpactPredictor().

local vecImpact is vecDraw().
local vecLanding is vecDraw().
until false {
    // impact prediction
    local impact is impactPredictor:getImpactPos(
        ship:position, ship:velocity:orbit
    ).
    if impact:isFound {
        set vecImpact to vecDraw(ship:position, impact:geoposition:altitudePosition(impact:altitude), red, "impact", 1, true).
        print "impact at lat "
            + round(impact:geoposition:lat, 6) + " lon "
            + round(impact:geoposition:lng, 6) + " alt "
            + round(impact:altitude, 2) + "m                    "
            at (0, 10).
    } else {
        print "no impact found" at (0, 10).
    }
    
    //// landing prediction
    //local landing is impactPredictor:getLandingPos(
    //    ship:position, ship:velocity:orbit
    //).
    //if landing:isFound {
    //    set vecLanding to vecDraw(ship:position, landing:geoposition:altitudePosition(landing:altitude), green, "landing", 1, true).
    //    print "landing at lat "
    //        + round(landing:geoposition:lat, 6) + " lon "
    //        + round(landing:geoposition:lng, 6) + " alt "
    //        + round(landing:altitude, 2) + "m (start alt "
    //        + round(landing:startAltitude) + "m)                    "
    //        at (0, 13).
    //} else {
    //    print "no landing found" at (0, 13).
    //}
    wait 0.
}

