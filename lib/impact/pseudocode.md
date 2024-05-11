# pseudocode

```
function bsaHit(currentAlt, bsa):
    return currentAlt <= bsa


function estimateBsa():
    return 1000


function updateBsa(prevBsa):
    impactLat = 
    impactLong = 
    bsa = prevBsa - impactAlt


function initiateBurn():
    // set up throttle PID controller
    // set up lat/long PIDs
    // make sure we land straight (for the last few seconds till impact, point retrograde)


function precisionLand(targetGeocoordinates):
    landingBurnStage = false
    bsa = estimateBsa()

    // set up trigger to see if we've hit the BSA
    when bsaHit(altitude, bsa):
        landingBurnStage = true

    // now, looping until we get to the landing burn stage
    until landingBurnStage:
        // get new BSA estimate
        updateBsa()
        // steer the ship
        updatePids()
    
    initiateBurn()
```
