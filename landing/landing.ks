@lazyGlobal off.
clearScreen.
clearVecDraws().

runOncePath("0:/lib/landing/landing.ks").

local precisionLander is PrecisionLander().

precisionLander:land(latLng(0, -73)).
