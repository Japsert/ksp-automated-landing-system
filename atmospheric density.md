# The drag equation

$$F_D = \frac{1}{2} * ρ * v² * C_d * A$$

where:

- $ρ$: atmospheric density (kg/m³)
- $v$: ship's surface velocity (m/s)
- $C_d$: coefficient of drag
- $A$: cross-sectional area (m²)

The plan is to calculate $C_d \cdot A$. We have:

- $F_D$: get from game somehow?
- $ρ$: two ways to get this:
    - thermometer + barometer:
        - the thermometer shows $P$, the static pressure
        - the barometer shows $T$, the temperature
        - we know Kerbin's molar mass $M$
        - so we can calculate the density ρ with the formula $ρ = \frac{P}{RT}$.
    - dynamic pressure + surface velocity:
        - `ship:q` returns dynamic pressure
        - `ship:groundspeed` returns velocity relative to surface (and thus to atmosphere)
        - so we can calculate the density $ρ$ by rewriting the formula $Q = \frac{1}{2} \cdot ρ \cdot v²$ (where $Q$ is dynamic pressure and $v$ is surface velocity) to $ρ = \frac{2Q}{v²}$.
            - Note: to do this in kOS, we can do `set atmDensity to (2 * ship:q) / ship:velocity:surface:sqrmagnitude`.

    I'm going to implement both methods and see how they compare.
- $v$: `ship:groundspeed`. TODO: compare to `ship:velocity:surface:mag`.

With these values, we will get values for $C_d \cdot A$ throughout the atmosphere. If we assume the surface area $A$ is constant, we can plot $C_d$ as a function of altitude and velocity, in a 3D surface plot. The resulting plot will apparently look like its real life counterpart; decreasing as the altitude decreases, with a spike at Mach 1.

I'll have to launch to a number of altitudes to get enough values for the velocity. I'll see through trial and error which altitudes I'll launch to.
