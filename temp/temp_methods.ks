// Log temperature data throughout the atmosphere from both the altTemp()
// function and the getSAT() function from AtmoData
// (https://github.com/Ren0k/Atmospheric-Data)
// in order to compare them and build a lookup table for getSAT().
@lazyGlobal off.

runOncePath("AtmoData/Time.ks").
runOncePath("AtmoData/AtmoData.ks").

global Timer is ClassTime(body, ship).

global logPath is "0:/temp/temp_night.log".
log "alt,altTemp(),getSAT()" to logPath.
global exit is false.

lock steering to up.
lock throttle to 1.
stage.

when ship:apoapsis >= 80000 then {
    lock throttle to 0.
    
    when ship:altitude >= 70000 then {
        set exit to true.
    }
}

local timeInFuture is 0.
local updateInterval is 50.
local getSAT is getAtmosphericData()["getSAT"](true).
until exit {
    local altTemp is body:atm:altTemp(ship:altitude).
    local SAT is getSAT(ship:altitude, ship:geoposition, timeInFuture, updateInterval).
    log list(ship:altitude, altTemp, SAT):join(",") to logPath.
    wait 0.
}
