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
            set interpolatedValue to oldValue - dValue * ticksSinceUpdate / ticksPerUpdate.
        }
    } else {
        // value updated
        if not canInterpolate and dValue <> 0 {
            set canInterpolate to true.
        }
        set dValue to oldValue - newValue.
        set ticksPerUpdate to ticksSinceUpdate.
        set ticksSinceUpdate to 0.
        set interpolatedValue to newValue.
        set oldValue to newValue.
    }
    printAt("interpolated speed: " + interpolatedValue, 0, 11).
    
    // print variables for debugging
    printAt("ticksPerUpdate: " + ticksPerUpdate, 0, 13).
    printAt("ticksSinceLastValue: " + ticksSinceUpdate, 0, 14).
    printAt("oldValue: " + oldValue, 0, 15).
    printAt("newValue: " + newValue, 0, 16).
    printAt("dValue: " + dValue, 0, 17).
    
    preserve.
}

until false {
    wait 1.
    set value to verticalSpeed.
    printAt("vertical speed:     " + value, 0, 10).
}
