@lazyGlobal off.

// Function that returns the number of instructions that a given delegate
// function has executed (excluding calling the function).
function getInstructionCount {
    local parameter f. // delegate function
    
    local count is opcodesLeft.
    f().
    set count to count - opcodesLeft - 3 - 8. // 3 for the count, 8 for the function call
    
    return count.
}

local l is list(1, 2, 3, 4, 5, 6).
local i is 3.
print(getInstructionCount({
    local value is l[i].
})).
