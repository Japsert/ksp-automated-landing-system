# Drag prediction

## Coefficient of drag profile

The plan is to use the drag equation to build up a "profile" of the coefficient of drag $C_d$ of my ship.

The drag equation is:

$$F_D = \frac{1}{2} \cdot ρ \cdot v² \cdot C_d \cdot A$$

where:

- $ρ$: atmospheric density (kg/m³)
- $v$: ship's surface velocity (m/s)
- $C_d$: coefficient of drag
- $A$: cross-sectional area (m²)

The plan is to calculate $C_d \cdot A$. We have:

- $F_D$: subtract thrust and gravity forces acting on the ship. The remaining force, measured by comparing real vertical and horizontal acceleration with the expected acceleration, is the drag force.
- $ρ$: two ways to get this:
    - thermometer + barometer:
        - the thermometer shows $P$, the static pressure
        - the barometer shows $T$, the temperature
        - we know Kerbin's molar mass $M$
        - so we can calculate the density ρ with the formula $ρ = \frac{PM}{RT}$ (where $R$ is the ideal gas constant).
    - dynamic pressure + surface velocity:
        - `ship:q` returns dynamic pressure
        - `ship:groundspeed` returns velocity relative to surface (and thus to atmosphere)
        - so we can calculate the density $ρ$ by rewriting the formula $Q = \frac{1}{2} \cdot ρ \cdot v²$ (where $Q$ is dynamic pressure and $v$ is surface velocity) to $ρ = \frac{2Q}{v²}$.
            - Note: to do this in kOS, we can do `set atmDensity to (2 * ship:q) / ship:velocity:surface:sqrmagnitude`.

    The second method is more accurate (at least at high dynamic pressures), because the thermometer used in the first method reports the wrong temperature (the external temperature, not the ambient temperature).
- $v$: `ship:groundspeed`.

With these values, we will get values for $C_d \cdot A$ throughout the atmosphere. If we assume the surface area $A$ is constant, we can plot $C_d$ as a function of altitude and velocity, in a 3D surface plot. The resulting plot will apparently look like its real life counterpart; decreasing as the altitude decreases, with a spike at Mach 1.

I'll have to launch to a number of altitudes to get enough values for the velocity. I'll see through trial and error which altitudes I'll launch to.

### Step by step

#### During flight

1. Launch until a certain apoapsis (e.g. 100 km).
2. When we hit the atmosphere, start measuring the drag force and atmospheric density each tick, and calculate $C_d \cdot A$ using the rewritten drag equation $C_d \cdot A = \frac{2F_D}{ρv²}$.
3. When we hit the ground, the program will stop (because the CPU is destroyed lol).

#### Analysis

1. Calculate $C_d \cdot A$ for each measurement.
2. Plot $C_d \cdot A$ as a function of altitude and velocity.

## The next step

The next step to being able to account for drag in impact estimation is to calculate the drag at any point in the atmosphere. For this, we need the atmospheric density at that point, the ship's velocity, the coefficient of drag, and the cross-sectional area.

- We can calculate the atmospheric density at any point with the 

...
