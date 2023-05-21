clearscreen.

// This script will launch a rocket up and to the side, and then try to land it at a specific location.

// Get current distance to the ground, starting from the lowest point of the ship
local bounds_box is ship:bounds.
lock groundHeight to bounds_box:BOTTOMALTRADAR.

lock steering to up.
print "locking steering to up".
lock throttle to 1.0.
stage.

when groundHeight >= 5 then {
    print "locking steering to 90, 70".
    lock steering to heading(90, 70).
    
    when groundHeight >= 1000 then {
        print "locking steering to prograde".
        lock throttle to 0.
        lock steering to srfPrograde.
        
        when verticalSpeed <= 10 then {
            print "locking steering to retrograde".
            rcs on.
            lock steering to srfRetrograde.
            
            when vectorAngle(ship:facing:vector, srfRetrograde:vector) <= 2 then {
                rcs off.
            }
            
            
        }
    }
}

until false {
    printAt("ground height: " + round(groundHeight, 2), 0, 10).
    printAt("facing: " + ship:facing, 0, 11).
    printAt("angle to retrograde: " + vectorAngle(ship:facing:vector, srfRetrograde:vector), 0, 12).
}
