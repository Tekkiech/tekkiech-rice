//@ pragma UseQApplication

import "modules"
import QtQuick
import Quickshell

// Entry point. Quickshell looks for this at
// ~/.config/quickshell/<name>/shell.qml — see install.sh, which symlinks
// this repo's quickshell/tekkiech/ there.
ShellRoot {
    id: root

    // Shared so the control center's Focus toggle can actually suppress
    // Notifications.qml's toasts — separate files don't share state
    // otherwise, so this lives at the one place that imports both.
    property bool dndOn: false

    Bar {}
    Launcher {}
    ControlCenter {
        dndOn: root.dndOn
        onDndToggleRequested: root.dndOn = !root.dndOn
    }
    Notifications {
        suppressed: root.dndOn
    }
    OSD {}
    LockScreen {}
}
