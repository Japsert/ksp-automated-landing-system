## The problem

- so we calculate the next geopos/alt of the ship, with intervals of 15 seconds, using RK4.
- however, this will result in a very inaccurate landing burn start altitude estimation.
- so we use a binary search to find the exact altitude at which the landing burn should start, using Euler's method.

## The solution

1. each iteration:
    1. check if should fully calculate the landing burn (using a very sophisticated, yet-to-be-thought-of algorithm)
    2. if so:
        1. iteratively determine where we would end up if we fired the engines at this iteration, using Euler's method
        2. when an iteration's landing burn ends up under the ground:
            1. return the final position using interpolation
            2. stop all iteration and report the start altitude and end up geopos/alt!

vertical speed is the magnitude of the velocity vector projected on the radial out (up) vector.
