global ERROR_LINE is 30.
global errorBuffer is list().

global debug is false.

// DEBUG
function repeatString {
    local parameter string.
    local parameter count.
    
    local result is "".
    for i in range(0, count) {
        set result to result + string.
    }
    return result.
}

function printLine {
    local parameter string.
    local parameter line.
    
    local stringLineCount is 0.
    if string:length = 0 set stringLineCount to 1.
    else set stringLineCount to ceiling(string:length / terminal:width).
    print string:padRight(stringLineCount * terminal:width) at (0, line).
}

//printLine(repeatString("M", 300), 10).
//printLine("", 11).
//printLine("Hello, world!", 12).
//printLine(repeatString("a", 70), 13).


// DEBUG: helper function
function printError {
    local parameter msg.
    
    local height is terminal:height - 1. // last line is not used?
    
    function spaceForNewMsg {
        local parameter msg.
        
        local i is ERROR_LINE.
        for error in errorBuffer {
            local lineCount is ceiling(error:length / terminal:width).
            set i to i + lineCount.
        }
        local msgLineCount is ceiling(msg:length / terminal:width).
        
        return i + msgLineCount <= height.
    }
    
    // Remove old messages if necessary
    until spaceForNewMsg(msg) {
        errorBuffer:remove(0).
    }
    errorBuffer:add(msg).
    
    // Print the buffer
    local i is ERROR_LINE.
    for error in errorBuffer {
        printLine(error, i).
        local lineCount is ceiling(error:length / terminal:width).
        set i to i + lineCount.
    }
    
    // Clear the rest of the lines
    until i >= height {
        printLine("", i).
        set i to i + 1.
    }
}

clearScreen.
set waitTime to 2.5.
print "ERROR BUFFER:" at (0, ERROR_LINE - 1).
printError("error: line 30,                                   31").
wait waitTime.
printError("error: line 32").
wait waitTime.
printError("error: line 33,                                   34,                                               35").
wait waitTime.
printError("error: line 36"). // should have no room. the first error should be removed.
wait waitTime.
printError("error: line 37"). // no room again, the second error should be removed.
wait waitTime.
printError("error: line 38"). // no room again, the third error should be removed.
wait waitTime.
printError("error: line 39"). // now there should be room again.
wait waitTime.
printError("error: line 40"). // for this one too.
wait waitTime.
printError("error: line 41"). // but not for this one, line 36 should be removed.
