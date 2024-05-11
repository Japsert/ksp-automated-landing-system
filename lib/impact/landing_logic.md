# landing burn start altitude estimation logic (yessir)

basically, keep track of a variable that has the burn start altitude from the previous time it was calculated. then when we reach that distance from the ground in our iterations, recalculate the burn, and update the burn start altitude for the next iteration.

this variable needs to be (very roughly) guessed the first iteration. we can first hardcode it, and later improve the estimation.

with this altitude and the expected landing location that we calculated, we can steer the rocket to influence it.
we use a few PID controllers, one for latitude, one for longitude. this will be challenging, since the feedback loop is long. we'll have to make slow adjustments.

then, when we expect to hit the burn start altitude, we can start burning. we use another PID controller to control the throttle, and change the lat/long PIDs, as they need to go the opposite direction now because of the direction of the force from the engines.

this should make us land at exactly the right spot.
