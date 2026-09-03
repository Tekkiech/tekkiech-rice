import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "common"

// Matches LockScreen.dc.html in /mockup. The actual lock/unlock plumbing
// (WlSessionLock + PamContext) is adapted from Quickshell's official
// lockscreen example — see LockContext.qml. This is a plain Item, not a
// ShellRoot: it's instantiated as a child of shell.qml's one ShellRoot,
// same as Bar and Launcher.
Item {
    id: root

    LockContext {
        id: lockContext
        onUnlocked: lock.locked = false
    }

    IpcHandler {
        target: "lock"
        function activate(): void {
            lock.locked = true;
        }
    }

    WlSessionLock {
        id: lock

        WlSessionLockSurface {
            Theme { id: theme }

            Rectangle {
                anchors.fill: parent
                color: theme.bg

                Column {
                    anchors.centerIn: parent
                    spacing: 26

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6

                        Text {
                            id: clock
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(new Date(), "hh:mm")
                            font.family: theme.fontMono
                            font.pixelSize: 96
                            font.weight: Font.Medium
                            color: theme.text

                            Timer {
                                interval: 1000
                                running: true
                                repeat: true
                                onTriggered: clock.text = Qt.formatDateTime(new Date(), "hh:mm")
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
                            font.family: theme.fontMono
                            font.pixelSize: 16
                            color: theme.textDim
                        }
                    }

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 48
                            height: 48
                            radius: 24
                            color: theme.surfaceSoft
                            border.width: 1
                            border.color: theme.borderStrong

                            Text {
                                anchors.centerIn: parent
                                text: Quickshell.env("USER") ? Quickshell.env("USER").charAt(0).toUpperCase() : "?"
                                font.family: theme.fontMono
                                font.pixelSize: 17
                                font.weight: Font.DemiBold
                                color: theme.text
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Quickshell.env("USER") ?? ""
                            font.family: theme.fontSans
                            font.pixelSize: 13
                            color: theme.textDim
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 260
                        height: 48
                        radius: theme.radiusMd
                        color: theme.surface
                        border.width: 1
                        border.color: theme.borderStrong

                        TextInput {
                            id: passwordField
                            anchors.fill: parent
                            anchors.leftMargin: 18
                            anchors.rightMargin: 44
                            verticalAlignment: TextInput.AlignVCenter
                            color: theme.text
                            font.family: theme.fontSans
                            font.pixelSize: 14
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            focus: true
                            enabled: !lockContext.unlockInProgress

                            onTextChanged: lockContext.currentText = text
                            onAccepted: lockContext.tryUnlock()

                            Connections {
                                target: lockContext
                                function onCurrentTextChanged() {
                                    if (passwordField.text !== lockContext.currentText)
                                        passwordField.text = lockContext.currentText;
                                }
                            }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32
                            height: 32
                            radius: 16
                            color: theme.white

                            Icon {
                                anchors.centerIn: parent
                                name: "arrow-right"
                                size: 14
                                color: "#151515"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: lockContext.tryUnlock()
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: lockContext.showFailure ? "Incorrect password" : "Press Enter to unlock"
                        font.family: theme.fontMono
                        font.pixelSize: 12
                        color: lockContext.showFailure ? "#e5a1a1" : theme.textFaint
                    }
                }
            }
        }
    }
}
