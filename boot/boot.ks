wait until ship:unpacked.
clearscreen.

cd("0:/boot/").
list files in bootFiles.
for file in bootFiles {
    if file:isFile and file:name <> "boot.ks" {
        copyPath("0:/boot/" + file:name, "1:/").
    }
}

core:doevent("Open Terminal").
