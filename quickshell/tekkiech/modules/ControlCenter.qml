import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import "common"

// Matches ControlCenter.dc.html in /mockup. Toggle with SUPER+C (see
// hypr/hyprland.conf) or `qs -c tekkiech ipc call controlcenter toggle`.
// Wi-Fi/Bluetooth read+write go through nmcli/bluetoothctl (see Bar.qml's
// header comment for why — no native Quickshell service for either).
// DND is a local UI toggle only for now; it doesn't yet suppress
// Notifications.qml (that needs a shared singleton — future work).
PanelWindow {
    id: panel

    visible: false
    focusable: visible

    anchors {
        top: true
        right: true
    }
    implicitWidth: 400
    implicitHeight: Math.max(screen.height, 1)
    color: "transparent"
    exclusiveZone: 0

    Theme { id: theme }

    property bool wifiOn: false
    property bool bluetoothOn: false
    property bool dndOn: false // bound from shell.qml's shared root property
    property bool airplaneOn: false
    property real brightness: 50

    signal dndToggleRequested()

    function open() { panel.visible = true; refresh(); }
    function close() { panel.visible = false; }

    IpcHandler {
        target: "controlcenter"
        function toggle(): void {
            panel.visible ? panel.close() : panel.open();
        }
    }

    function refresh() {
        wifiStatusProc.running = false; wifiStatusProc.running = true;
        btStatusProc.running = false; btStatusProc.running = true;
        brightnessProc.running = false; brightnessProc.running = true;
    }

    Timer {
        interval: 5000
        running: panel.visible
        repeat: true
        onTriggered: panel.refresh()
    }

    Process {
        id: wifiStatusProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: panel.wifiOn = text.trim() === "enabled" }
    }

    Process {
        id: btStatusProc
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector { onStreamFinished: panel.bluetoothOn = /Powered:\s*yes/.test(text) }
    }

    Process {
        id: brightnessProc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",");
                if (parts.length >= 4) panel.brightness = parseFloat(parts[3]);
            }
        }
    }

    function setWifi(on) {
        wifiOn = on;
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]);
    }
    function setBluetooth(on) {
        bluetoothOn = on;
        Quickshell.execDetached(["bluetoothctl", "power", on ? "on" : "off"]);
    }
    function setAirplane(on) {
        airplaneOn = on;
        Quickshell.execDetached(["nmcli", "radio", "all", on ? "off" : "on"]);
    }
    function setBrightness(pct) {
        brightness = pct;
        Quickshell.execDetached(["brightnessctl", "set", Math.round(pct) + "%"]);
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

    // Scrim + click-outside-to-close
    MouseArea {
        anchors.fill: parent
        onClicked: panel.close()
    }

    Rectangle {
        id: card
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 22
        anchors.topMargin: 60
        width: 380
        radius: theme.radiusLg
        color: theme.surface
        border.width: 1
        border.color: theme.borderStrong
        height: content.implicitHeight + 44

        MouseArea { anchors.fill: parent } // swallow clicks so scrim doesn't close on them

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 22
            spacing: 22

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    radius: 19
                    color: theme.surfaceSoft
                    border.width: 1
                    border.color: theme.borderStrong

                    Text {
                        anchors.centerIn: parent
                        text: Quickshell.env("USER") ? Quickshell.env("USER").charAt(0).toUpperCase() : "?"
                        font.family: theme.fontMono
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: theme.text
                    }
                }

                Text {
                    text: Quickshell.env("USER") ?? ""
                    font.family: theme.fontSans
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: theme.text
                }

                Item { Layout.fillWidth: true }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 10
                rowSpacing: 10

                component ToggleTile: Rectangle {
                    property bool on: false
                    property string label: ""
                    property string icon: ""
                    signal activated()

                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: 14
                    color: on ? theme.white : theme.surfaceSoft
                    border.width: on ? 0 : 1
                    border.color: theme.border

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: icon
                            size: 16
                            color: on ? "#151515" : theme.textDim
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: label
                            font.family: theme.fontMono
                            font.pixelSize: 10
                            color: on ? "#151515" : theme.textDim
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.activated()
                    }
                }

                ToggleTile { label: "Wi-Fi"; icon: "wifi"; on: panel.wifiOn; onActivated: panel.setWifi(!panel.wifiOn) }
                ToggleTile { label: "Bluetooth"; icon: "bluetooth"; on: panel.bluetoothOn; onActivated: panel.setBluetooth(!panel.bluetoothOn) }
                ToggleTile { label: "Focus"; icon: "moon"; on: panel.dndOn; onActivated: panel.dndToggleRequested() }
                ToggleTile { label: "Airplane"; icon: "airplane"; on: panel.airplaneOn; onActivated: panel.setAirplane(!panel.airplaneOn) }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 14

                component SliderRow: RowLayout {
                    property string icon: ""
                    property real value: 0
                    signal moved(real pct)

                    spacing: 12

                    Icon {
                        name: icon
                        size: 15
                        color: theme.textDim
                        Layout.preferredWidth: 16
                    }

                    Rectangle {
                        id: track
                        Layout.fillWidth: true
                        height: 5
                        radius: 3
                        color: theme.track

                        Rectangle {
                            width: track.width * Math.max(0, Math.min(1, value / 100))
                            height: parent.height
                            radius: 3
                            color: theme.white
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            onPressed: mouse => moved(Math.max(0, Math.min(1, mouse.x / track.width)) * 100)
                            onPositionChanged: mouse => {
                                if (pressed) moved(Math.max(0, Math.min(1, mouse.x / track.width)) * 100);
                            }
                        }
                    }

                    Text {
                        text: Math.round(value) + "%"
                        font.family: theme.fontMono
                        font.pixelSize: 11
                        color: theme.textFaint
                        Layout.preferredWidth: 30
                        horizontalAlignment: Text.AlignRight
                    }
                }

                SliderRow {
                    Layout.fillWidth: true
                    icon: "volume"
                    value: (Pipewire.defaultAudioSink?.audio?.volume ?? 0) * 100
                    onMoved: pct => { if (Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.volume = pct / 100; }
                }

                SliderRow {
                    Layout.fillWidth: true
                    icon: "brightness-rays"
                    value: panel.brightness
                    onMoved: pct => panel.setBrightness(pct)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 62
                radius: 14
                color: theme.surfaceSoft
                border.width: 1
                border.color: theme.border
                visible: panel.player !== null

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: panel.player?.trackTitle ?? ""
                            font.family: theme.fontSans
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: theme.text
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: panel.player?.trackArtist ?? ""
                            font.family: theme.fontMono
                            font.pixelSize: 11
                            color: theme.textFaint
                            elide: Text.ElideRight
                        }
                    }

                    Item {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16

                        Icon {
                            visible: !panel.player?.isPlaying
                            anchors.fill: parent
                            name: "play"
                            color: theme.textDim
                        }

                        Row {
                            visible: panel.player?.isPlaying ?? false
                            anchors.centerIn: parent
                            spacing: 3
                            Rectangle { width: 4; height: 14; color: theme.textDim }
                            Rectangle { width: 4; height: 14; color: theme.textDim }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            cursorShape: Qt.PointingHandCursor
                            onClicked: panel.player?.togglePlaying()
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4

                component PowerButton: Rectangle {
                    property string icon: ""
                    signal activated()
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    radius: 21
                    color: "transparent"
                    border.width: 1
                    border.color: theme.borderStrong

                    Icon {
                        anchors.centerIn: parent
                        name: icon
                        size: 16
                        color: theme.textDim
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.activated()
                    }
                }

                PowerButton { icon: "lock"; onActivated: Quickshell.execDetached(["qs", "-c", "tekkiech", "ipc", "call", "lock", "activate"]) }
                Item { Layout.fillWidth: true }
                PowerButton { icon: "moon"; onActivated: Quickshell.execDetached(["systemctl", "suspend"]) }
                Item { Layout.fillWidth: true }
                PowerButton { icon: "restart"; onActivated: Quickshell.execDetached(["systemctl", "reboot"]) }
                Item { Layout.fillWidth: true }
                PowerButton { icon: "power"; onActivated: Quickshell.execDetached(["systemctl", "poweroff"]) }
            }
        }
    }
}
