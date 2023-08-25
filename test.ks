@lazyGlobal off.
clearScreen.
clearVecDraws().

local angvel is 0.
until false {
    local newangvel is body:angularvel:mag.
    if newangvel <> angvel {
        print newangvel.
    }.
    set angvel to newangvel.
    wait 0.
}
