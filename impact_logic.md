# Impact estimation function

1. get initial values
    - geoposition
    - altititude
    - velocity
2. calculate new pos/alt
    1. determine forces acting on rocket (vectors)
        - gravity
            - -g * up
        - drag
            - 1/2 * atmDensityPa * sqrVelocity * CdA
    2. calculate sum of forces (vector)
    3. determine new acceleration vector (force sum / mass)
        - this is the change in velocity during this time step
    4. determine new velocity vector
        - new vel vec = prev vel vec + new acc vec * dt
    5. determine new position/altitude
        - the change in position is the velocity vector * dt
        - this results in a vector, the end of which indicates where we will be
          after the time step
    6. use body:geopositionOf and body:altitudeOf to get the new position and
       altitude, taking into account curvature of Kerbin
3. check if we have reached the ground. if we have, interpolate positions to
   find impact position; if not, return to step 2.

## Other ideas

- maybe, we could calculate the impact position without a limit on the iterations the first
  iteration that we run the script, and

- we can vary step size to place more steps where drag is greater?
- we can vary step size to have as many steps as n tick(s) will allow for?
