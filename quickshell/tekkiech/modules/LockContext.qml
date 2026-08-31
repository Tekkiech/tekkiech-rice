import QtQuick
import Quickshell
import Quickshell.Services.Pam

// Adapted near-verbatim from Quickshell's official lockscreen example
// (quickshell-mirror/quickshell-examples, lockscreen/LockContext.qml) —
// this is auth code, not something to improvise on. Shared state so all
// per-monitor LockSurfaces (see LockScreen.qml) stay in sync.
Scope {
    id: root
    signal unlocked()

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    onCurrentTextChanged: showFailure = false

    function tryUnlock() {
        if (currentText === "") return;
        root.unlockInProgress = true;
        pam.start();
    }

    PamContext {
        id: pam

        // A dedicated pam config (see ../pam/password.conf) rather than
        // relying on the system default, so this doesn't silently break
        // if that config expects something this UI doesn't provide.
        configDirectory: Quickshell.shellDir + "/pam"
        config: "password.conf"

        onPamMessage: {
            if (this.responseRequired) {
                this.respond(root.currentText);
            }
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlocked();
            } else {
                root.currentText = "";
                root.showFailure = true;
            }
            root.unlockInProgress = false;
        }
    }
}
