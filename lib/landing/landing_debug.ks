@lazyGlobal off.

global DEBUG is true.

local drawDebugVecs is false.
when terminal:input:hasChar then {
    local c is terminal:input:getChar().
    if c = "q" {
        set drawDebugVecs to true.
        print "drawing debug vectors".
    } else if c = "c" {
        clearVecDraws().
        clearScreen.
    }
    preserve.
}

function drawDebugVec {
    local parameter newGeopos.
    local parameter newAlt.
    local parameter geopos.
    local parameter alt_.
    local parameter color.

    local vecToNewPos is newGeopos:altitudePosition(newAlt).
    local vecToOldPos is geopos:altitudePosition(alt_).
    local vec is vecToNewPos - vecToOldPos.
    return vecDraw(
        { return geopos:altitudePosition(alt_). },
        vec, color, "", 1, true
    ).
}

// Precision lander class
function PrecisionLander {

    // Constructor
    // simulation parameters
    local dT is .5.
    local halfDT is dT / 2.
    local sixthDT is dT / 6.

    // constants
    local mu is body:mu.
    local atm is body:atm.
    local engine is ship:engines[0].

    local throttleAmount is 1.
    local bodyRotationPerIteration is 2 * constant:pi / body:rotationPeriod * constant:radToDeg * dT.

    // trajectory variables
    local bsa is _estimateBsa().
    local impactGeocoords is latLng(0, 0).

    // PID controllers
    local pidThrottle is pidLoop(0.1).
    local pidLat is pidLoop(0.1).
    local pidLng is pidLoop(0.1).

    // private functions
    function _estimateBsa {
        return 3200.
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
        local thrustAcc is throttleAmount * engine:possibleThrustAt(staticPressure) / mass.
        local thrustAccVec is thrustAcc * -velVecSrf:normalized.
        if velVecSrf:mag < 20
            set thrustAccVec to thrustAcc * centerToPosVec:normalized.

        return gravAccVec + thrustAccVec.
    }

    function _simulateBurn {
        // TODO: drag
        // TODO: depleting fuel
        // TODO: account for terrain
        local posVec is ship:position.
        local velVec is ship:velocity:orbit.

        local startBurnSim is false.
        local i is 0.
        local geopos is body:geopositionOf(posVec).
        local alt_ is body:altitudeOf(posVec).
        local drawDebugVecsThisIteration is drawDebugVecs.

        until startBurnSim {
            set i to i + 1.

            // iterate on current pos/vel using RK4
            local k1VelVec is velVec.
            local k1AccVec is _getAccVec(posVec, k1VelVec).
            local k2VelVec is velVec + k1AccVec * halfDT.
            local k2AccVec is _getAccVec(posVec + k1VelVec * halfDT, k2VelVec).
            local k3VelVec is velVec + k2AccVec * halfDT.
            local k3AccVec is _getAccVec(posVec + k2VelVec * halfDT, k3VelVec).
            local k4VelVec is velVec + k3AccVec * dT.
            local k4AccVec is _getAccVec(posVec + k3VelVec * dT, k4VelVec).

            // update position and velocity
            local newPosVec is
                posVec + (k1VelVec + 2 * k2VelVec + 2 * k3VelVec + k4VelVec) * sixthDT.
            local newVelVec is
                velVec + (k1AccVec + 2 * k2AccVec + 2 * k3AccVec + k4AccVec) * sixthDT.

            local newGeopos is body:geopositionOf(newPosVec).
            set newGeopos to latLng(newGeopos:lat, newGeopos:lng - bodyRotationPerIteration * i).
            local newAlt is body:altitudeOf(newPosVec).

            if newAlt <= bsa {
                set startBurnSim to true.
                // interpolate
                local interpRatio is (alt_ - bsa) / (alt_ - newAlt).
                set newPosVec to posVec + (newPosVec - posVec) * interpRatio.
                set newVelVec to velVec + (newVelVec - velVec) * interpRatio.
                set newGeopos to body:geopositionOf(posVec).
                set newAlt to body:altitudeOf(posVec).
                set i to i + interpRatio.
                break.
            }

            if drawDebugVecsThisIteration {
                drawDebugVec(newGeopos, newAlt, geopos, alt_, red).
            }

            set posVec to newPosVec.
            set velVec to newVelVec.
            set geopos to newGeopos.
            set alt_ to newAlt.
        }

        until false {
            set i to i + 1.

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
            local radialOutVec is (newPosVec - body:position):normalized.
            if vDot(newVelVec, radialOutVec) > 0
                break.

            // draw debug vectors
            local newGeopos is body:geopositionOf(newPosVec).
            set newGeopos to latLng(newGeopos:lat, newGeopos:lng - bodyRotationPerIteration * i).
            local newAlt is body:altitudeOf(newPosVec).
            if drawDebugVecsThisIteration {
                drawDebugVec(newGeopos, newAlt, geopos, alt_, yellow).
            }

            set posVec to newPosVec.
            set velVec to newVelVec.
            set geopos to newGeopos.
            set alt_ to newAlt.
        }

        set bsa to bsa - body:altitudeOf(posVec).
        set impactGeocoords to body:geopositionOf(posVec). // TODO: body rotation

        // DEBUG
        print "BSA: " + round(bsa, 2) at (0,10).
        print "Impact: " + round(impactGeocoords:lat, 2) + " " + round(impactGeocoords:lng, 2) at (0,11).
        if drawDebugVecsThisIteration set drawDebugVecs to false.
    }

    function _updatePids {
        //pidLat:update(time:seconds, impactLat).
        //pidLng:update(time:seconds, impactLng).
    }

    function _initiateBurn {
        lock throttle to throttleAmount.
        // set up throttle PID controller
        set pidThrottle:setpoint to 1.
        // change lat/lng PIDs

        // make sure we land straight (for the last few seconds till impact, point retrograde)

        until verticalSpeed >= 0 {
            wait 0.
        }
        lock throttle to 0.
    }

    // public
    function land {
        parameter targetGeocoords.

        lock throttle to 0.
        set rcs to false.
        set navMode to "surface".
        set sasMode to "retrograde".

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
