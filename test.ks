clearScreen.

set value to 0.
set interpolatedValue to 1. // > 0

// trigger
when interpolatedValue <= 0 then {
    printAt("Fire the engines!", 20, 20).
}

// interpolate value trigger
set oldValue to value.
set ticksPerUpdate to 0.
set dValue to 0.
set interpolatedValue to value.
set ticksSinceUpdate to 0.
set canInterpolate to false.
when true then {
    set newValue to value.
    
    if oldValue = newValue {
        // no new value, interpolate
        set ticksSinceUpdate to ticksSinceUpdate + 1.
        if canInterpolate {
            set dValuePerTick to
                choose dValue / ticksPerUpdate
                if ticksPerUpdate <> 0
                else 0.
            set interpolatedValue to oldValue - dValuePerTick.
        }
    } else {
        // value updated
        if not canInterpolate and dValue <> 0 {
            // newValue is now our second known value,
            // so we know how much to interpolate by
            set canInterpolate to true.
        }
        
        set dValue to oldValue - newValue.
        set ticksPerUpdate to ticksSinceUpdate.
        set ticksSinceUpdate to 0.
        set interpolatedValue to newValue.
        set oldValue to newValue.
    }
    
    printAt("interpolated speed:  " + round(interpolatedValue, 2) + "    ", 0, 11).
    
    // print variables for debugging
    printAt("ticksPerUpdate:      " + round(ticksPerUpdate, 2) + "    ", 0, 13).
    printAt("ticksSinceLastValue: " + round(ticksSinceUpdate, 2) + "    ", 0, 14).
    printAt("oldValue:            " + round(oldValue, 2) + "    ", 0, 15).
    printAt("newValue:            " + round(newValue, 2) + "    ", 0, 16).
    printAt("dValue:              " + round(dValue, 2) + "    ", 0, 17).
    
    printAt("diff:                " + round(diff, 2) + "    ", 0, 19).
    
    preserve.
}

until false {
    wait 1.
    set value to verticalSpeed.
    printAt("vertical speed:      " + round(value, 2) + "    ", 0, 10).
}
