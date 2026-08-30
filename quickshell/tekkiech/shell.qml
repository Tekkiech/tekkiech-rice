//@ pragma UseQApplication

import "modules"
import QtQuick
import Quickshell

// Entry point. Quickshell looks for this at
// ~/.config/quickshell/<name>/shell.qml — see install.sh, which symlinks
// this repo's quickshell/tekkiech/ there.
ShellRoot {
    Bar {}
    Launcher {}
}
