// Precision Landing Library
// by Japsert, 2024

@lazyGlobal off.

// Precision lander class
function PrecisionLander {

    // Constructor
    // simulation parameters
    local dT is 5.
    local halfDT is dT / 2.
    local sixthDT is dT / 6.

    // constants
    local mu is body:mu.
    local atm is body:atm.
    local engine is ship:engines[0].

    // trajectory variables
    local bsa is _estimateBsa().
    local impactGeocoords is latLng(0, 0).

    // PID controllers
    local pidThrottle is pidLoop(0.1).
    local pidLat is pidLoop(0.1).
    local pidLng is pidLoop(0.1).

    // private functions
    function _estimateBsa {
        return 1000.
    }

    function _bsaHit {
        return ship:altitude <= bsa.
    }

    function _getAccVec {
        parameter posVec, velVec.

        local centerToPosVec is posVec - body:position.
        return (mu / centerToPosVec:sqrMagnitude) * -centerToPosVec:normalized.
    }

    function _getBurnAccVec {
        parameter posVec, velVec.

        // Gravity
        local centerToPosVec is posVec - body:position.
        local gravAccVec is (mu / centerToPosVec:sqrMagnitude) * -centerToPosVec:normalized.

        // Convert non-inertial velocity to inertial velocity
        local velVecSrf is velVec - vCrs(body:angularVel, centerToPosVec).

        // Thrust
        local alt_ is centerToPosVec:mag - body:radius.
        local staticPressure is atm:altitudePressure(alt_).
        local thrustAcc is engine:possibleThrustAt(staticPressure) / mass.
        local thrustAccVec is thrustAcc * -velVecSrf:normalized.

        return gravAccVec + thrustAccVec.
    }

    function _simulateBurn {
        // TODO: interpolate between posVec and newPosVec to be more accurate
        // TODO: drag
        // TODO: depleting fuel
        // TODO: account for terrain
        local posVec is ship:position.
        local velVec is ship:velocity:orbit.

        until false {
            // iterate on current pos/vel using RK4
            local k1VelVec is velVec.
            local k1AccVec is _getAccVec(posVec, k1VelVec).
            local k2VelVec is velVec + k1AccVec * halfDT.
            local k2AccVec is _getAccVec(posVec + k1VelVec * halfDT, k2VelVec).
            local k3VelVec is velVec + k2AccVec * halfDT.
            local k3AccVec is _getAccVec(posVec + k2VelVec * halfDT, k3VelVec).
            local k4VelVec is velVec + k3AccVec * dT.
            local k4AccVec is _getAccVec(posVec + k3VelVec * dT, k4VelVec).

            local newPosVec is
                posVec + (k1VelVec + 2 * k2VelVec + 2 * k3VelVec + k4VelVec) * sixthDT.
            local newVelVec is
                velVec + (k1AccVec + 2 * k2AccVec + 2 * k3AccVec + k4AccVec) * sixthDT.

            local newAlt is body:altitudeOf(newPosVec).
            if newAlt <= bsa
                break.

            set posVec to newPosVec.
            set velVec to newVelVec.
        }

        until false {
            // iterate, but now with burn acceleration
            local k1VelVec is velVec.
            local k1AccVec is _getBurnAccVec(posVec, k1VelVec).
            local k2VelVec is velVec + k1AccVec * halfDT.
            local k2AccVec is _getBurnAccVec(posVec + k1VelVec * halfDT, k2VelVec).
            local k3VelVec is velVec + k2AccVec * halfDT.
            local k3AccVec is _getBurnAccVec(posVec + k2VelVec * halfDT, k3VelVec).
            local k4VelVec is velVec + k3AccVec * dT.
            local k4AccVec is _getBurnAccVec(posVec + k3VelVec * dT, k4VelVec).

            local newPosVec is
                posVec + (k1VelVec + 2 * k2VelVec + 2 * k3VelVec + k4VelVec) * sixthDT.
            local newVelVec is
                velVec + (k1AccVec + 2 * k2AccVec + 2 * k3AccVec + k4AccVec) * sixthDT.

            // check radial out component of velocity
            local radialOutVec is (posVec - body:position):normalized.
            if (vDot(newVelVec, radialOutVec) * radialOutVec):mag > 0
                break.

            set posVec to newPosVec.
            set velVec to newVelVec.
        }

        set bsa to bsa - body:altitudeOf(posVec).
        set impactGeocoords to body:geopositionOf(posVec). // TODO: body rotation
    }

    function _updatePids {
        //pidLat:update(time:seconds, impactLat).
        //pidLng:update(time:seconds, impactLng).
    }

    function _initiateBurn {
        // set up throttle PID controller
        set pidThrottle:setpoint to 1.
        // change lat/lng PIDs

        // make sure we land straight (for the last few seconds till impact, point retrograde)
    }

    // public functions
    function land {
        parameter targetGeocoords.

        set pidLat:setpoint to targetGeocoords:lat.
        set pidLng:setpoint to targetGeocoords:lng.

        // set up trigger
        local landingBurnStage is false.
        when _bsaHit() then
            set landingBurnStage to true.

        until landingBurnStage {
            // correct BSA estimate
            _simulateBurn().

            // steer the ship
            _updatePids().
        }

        _initiateBurn().
    }

    return lexicon(
        "land", land@
    ).
}
