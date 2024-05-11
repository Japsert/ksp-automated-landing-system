# simulating a burn

if we were to fly perfectly retrograde, and initiate a landing burn at 80% throttle at the previously estimated BSA, what would the altitude and geocoordinates of our position at 0 velocity?

1. until the position is at BSA:
    1. iterate the current position and velocity using RK4
2. until the burn has ended:
    1. iterate the position and velocity, this time with burn acceleration
3. update BSA to account for the error in the final position
4. update impact lat/lng to final position
