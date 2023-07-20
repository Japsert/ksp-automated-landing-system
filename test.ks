clearScreen.
set COL2 to 28.

set lastTime to time:seconds.
set realVAcc to 0.
set lastVerticalSpeed to verticalSpeed.
when true then {
    set dt to time:seconds - lastTime.
    set realVAcc to (verticalSpeed - lastVerticalSpeed) * 1/dt.
    set lastTime to time:seconds.
    set lastVerticalSpeed to verticalSpeed.
    preserve.
}

until false {
    set facingVector to ship:facing:vector.
    printAt("facing: " + round(facingVector:x, 2) + "," + round(facingVector:y, 2) + "," + round(facingVector:z, 2) + "        ", 0, 0).
    
    set Fe to ship:availablethrust * throttle * facingVector:z.
    set g to body:mu / (body:radius + ship:altitude)^2.
    set Fz to ship:mass * g.
    set Fres to Fe - Fz.
    set a to Fres / ship:mass.
    // print Fe, g, Fz, Fres, a.
    printAt("Calculated:", 0, 1).
    printAt("Fe:     " + round(Fe, 2), 0, 2).
    printAt("g:      " + round(g, 2), 0, 3).
    printAt("Fz:     " + round(Fz, 2), 0, 4).
    printAt("Fres:   " + round(Fres, 2), 0, 5).
    printAt("a:      " + round(a, 2), 0, 6).
    set calcA to a.
    
    // print real versions of this
    set a to realVAcc.
    set Fres to a * ship:mass.
    set Fz to Fz.
    set Fe to Fres + Fz.
    printAt("Real:", COL2, 1).
    printAt("Fe:     " + round(Fe, 2), COL2, 2).
    printAt("Fres:   " + round(Fres, 2), COL2, 5).
    printAt("a:      " + round(a, 2), COL2, 6).
    
    // print diff between calculated and real acceleration
    printAt("     real - calc acceleration: " + round(a - calcA, 2) + "     ", 0, 7).
    
    set sensorAcc to ship:sensors:acc.
    printAt("Sensor: " + round(sensorAcc:x, 2) + ", " + round(sensorAcc:y, 2) + ", " + round(sensorAcc:z, 2) + "        ", 0, 9).
    set sensorGrav to ship:sensors:grav.
    printAt("Grav:   " + round(sensorGrav:x, 2) + ", " + round(sensorGrav:y, 2) + ", " + round(sensorGrav:z, 2) + "        ", 0, 10).
}
