runOncePath("0:/lib/impact/impact.ks").

local impactPredictor is ImpactPredictor().

local startTime is time:seconds.
local startOpcodes is opcodesLeft.

local impact is impactPredictor:getImpactPos(
    ship:position, ship:velocity:orbit
).

local endOpcodes is opcodesLeft.
local ticksElapsed is round((time:seconds - startTime) / 0.02).
local opcodesElapsed is ticksElapsed * config:IPU + startOpcodes - endOpcodes.

print impact.
print "took " + ticksElapsed + " ticks or " + opcodesElapsed + " opcodes.".
