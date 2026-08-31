import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.UPower
import "common"

// Full-width top bar. Flat, no rounding, matches Main.dc.html in /mockup.
// Workspaces and the active window title come live from Hyprland's IPC;
// battery comes from UPower. Wi-Fi/Bluetooth/mic have no dedicated
// Quickshell service module (confirmed against quickshell-mirror's own
// src/services/ listing — only greetd/mpris/notifications/pam/pipewire/
// polkit/status_notifier/upower exist), so they poll nmcli/bluetoothctl/
// wpctl on a timer instead, same approach real bars (waybar etc.) use.
PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 40
    color: "transparent"
    exclusiveZone: implicitHeight
    focusable: false

    Theme { id: theme }

    property string wifiSsid: ""
    property bool bluetoothOn: false
    property bool micMuted: false

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            wifiProc.running = false; wifiProc.running = true;
            btProc.running = false; btProc.running = true;
            micProc.running = false; micProc.running = true;
        }
    }

    Process {
        id: wifiProc
        command: ["nmcli", "-t", "-f", "active,ssid", "dev", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const active = text.split("\n").find(l => l.startsWith("yes:"));
                bar.wifiSsid = active ? active.slice(4) : "";
            }
        }
    }

    Process {
        id: btProc
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: bar.bluetoothOn = /Powered:\s*yes/.test(text)
        }
    }

    Process {
        id: micProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: StdioCollector {
            onStreamFinished: bar.micMuted = text.includes("[MUTED]")
        }
    }

    Rectangle {
        anchors.fill: parent
        color: theme.surface

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: theme.border
        }

        // Left: workspaces + active window title
        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Repeater {
                model: Hyprland.workspaces.values
                delegate: Rectangle {
                    required property var modelData
                    property bool active: Hyprland.focusedWorkspace?.id === modelData.id

                    width: 20
                    height: 20
                    radius: 5
                    color: active ? theme.white : "transparent"
                    border.width: active ? 0 : 1
                    border.color: theme.borderStrong

                    Text {
                        anchors.centerIn: parent
                        text: modelData.id
                        font.family: theme.fontMono
                        font.pixelSize: 11
                        color: active ? "#151515" : theme.textFaint
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Hyprland.dispatch("workspace " + modelData.id)
                    }
                }
            }

            Rectangle {
                Layout.leftMargin: 8
                Layout.rightMargin: 2
                width: 1
                height: 16
                color: theme.borderStrong
            }

            Text {
                Layout.maximumWidth: 420
                text: Hyprland.activeToplevel?.title ?? ""
                font.family: theme.fontMono
                font.pixelSize: 13
                color: theme.textDim
                elide: Text.ElideRight
            }
        }

        // Center: clock
        Text {
            id: clock
            anchors.centerIn: parent
            text: Qt.formatDateTime(new Date(), "hh:mm    ddd, MMM d")
            font.family: theme.fontMono
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: theme.text

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.text = Qt.formatDateTime(new Date(), "hh:mm    ddd, MMM d")
            }
        }

        // Right: battery, power
        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            Text {
                visible: bar.micMuted
                text: "mic muted"
                font.family: theme.fontMono
                font.pixelSize: 11
                color: theme.textFaint
            }

            Text {
                visible: bar.wifiSsid !== ""
                text: bar.wifiSsid
                font.family: theme.fontMono
                font.pixelSize: 12
                color: theme.textDim
            }

            Text {
                text: "bt"
                font.family: theme.fontMono
                font.pixelSize: 11
                color: bar.bluetoothOn ? theme.textDim : theme.textFaint
            }

            Text {
                readonly property var device: UPower.displayDevice
                text: device && device.ready ? Math.round(device.percentage) + "%" : "--"
                font.family: theme.fontMono
                font.pixelSize: 12
                color: theme.textDim
            }

            Rectangle {
                width: 1
                height: 16
                color: theme.borderStrong
            }

            Text {
                text: "⏻" // power glyph placeholder — swap for the mockup's stroke-icon SVG later
                font.pixelSize: 14
                color: theme.textDim

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("exit")
                }
            }
        }
    }
}
