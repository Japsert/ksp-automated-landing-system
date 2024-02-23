# landing burn start altitude estimation logic (yessir)

basically, keep track of a variable that has the burn start altitude from the previous time it was calculated. then when we reach that distance from the ground in our iterations, recalculate the burn, and update the burn start altitude for the next iteration.

this variable needs to be (very roughly) guessed the first iteration.
