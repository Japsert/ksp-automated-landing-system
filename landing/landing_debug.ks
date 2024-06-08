@lazyGlobal off.
clearScreen.
clearVecDraws().

runOncePath("0:/lib/landing/landing_debug.ks").

local precisionLander is PrecisionLander().

precisionLander:land(latLng(0, -73)).
