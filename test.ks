set startTime to time:seconds.
until false {
    set tick to (time:seconds - startTime) / 0.02.
    log tick + "," + throttle + "," + verticalSpeed to "logs/temp.log".
    wait 0.
}
