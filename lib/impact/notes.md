# notes

so right now, we have a pretty good estimate of where we're going to land. :D

at each iteration, we can also calculate the estimated burn start altitude. we could also even do this only every few iterations.

then, with this information, we can heuristically approximate the iteration at which we're expected to land.

after we actually predict the landing burn, we can see how far away we are from the surface.

with this number, we can take another iteration that is that number lower than our previous one.

after we do this a couple times, we'll have a good estimate of at what altitude we need to start burning to end up at 0 m/s at 0 m altitude.

    TODO: we first need to do some (thorough) testing to make sure the estimate is a good approximation!

