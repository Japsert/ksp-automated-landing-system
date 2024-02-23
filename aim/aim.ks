@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/impact/impact.ks").
local impactPredictor is ImpactPredictor().

// Initial burn
if ship:status = "prelaunch" {
    stage.
    lock steering to heading(90, 70).
    lock throttle to 1.
    wait 1.
    legs off.
    until kuniverse:timewarp:rate = 4 {
        set kuniverse:timewarp:rate to 4.
        wait 0.
    }
    when ship:apoapsis >= 11000 then {
        set kuniverse:timewarp:rate to 1.
        
        when ship:apoapsis >= 13000 then {
            lock throttle to 0.
            lock steering to srfRetrograde.
        }
    }
}

local vecImpact is vecDraw().
local targetGeopos is latLng(0, -72).
local vecTarget is vecDraw(ship:position, { return targetGeopos:position. }, green, "", 1, true).
until false {
    // Get impact position
    local impact is impactPredictor:getImpactPos(
        ship:position, ship:velocity:orbit
    ).
    if impact:isFound {
        set vecImpact to vecDraw(ship:position, impact:geoposition:altitudePosition(impact:altitude), red, "", 1, true).
    }
}
