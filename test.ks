function f {
    parameter p.
    set sum to 0.
    for i in range(500) {
        set sum to sum + p.
    }
    return sum.
}

lock a to f(ship:altitude).
lock b to f(a).

until false {
    printAt("b: " + b, 0, 0).
    printAt("a: " + a, 0, 1).
}
