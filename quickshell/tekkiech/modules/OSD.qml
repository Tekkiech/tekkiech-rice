import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "common"

// Matches OSD.dc.html in /mockup: a floating pill that appears briefly on
// volume/brightness change, then auto-hides. Volume is reactive (bound
// directly to Pipewire); brightness has no such bus to listen on, so the
// hyprland.conf brightness keybinds call `qs -c tekkiech ipc call osd
// showBrightness <percent>` after running brightnessctl.
PanelWindow {
    id: root

    anchors {
        bottom: true
    }
    implicitWidth: 260
    implicitHeight: 110
    color: "transparent"
    exclusiveZone: 0
    focusable: false
    visible: hideTimer.running

    Theme { id: theme }

    property real percent: 0
    property bool isBrightness: false

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio ?? null
        function onVolumeChanged() {
            root.isBrightness = false;
            root.percent = Pipewire.defaultAudioSink.audio.volume * 100;
            hideTimer.restart();
        }
    }

    IpcHandler {
        target: "osd"
        function showBrightness(value: string): void {
            root.isBrightness = true;
            root.percent = parseFloat(value);
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: 1600
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        width: 220
        height: 56
        radius: theme.radiusLg
        color: theme.surface
        border.width: 1
        border.color: theme.borderStrong

        Row {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.isBrightness ? "bri" : "vol"
                font.family: theme.fontMono
                font.pixelSize: 12
                color: theme.textDim
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 118
                height: 5
                radius: 3
                color: theme.track

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.percent / 100))
                    height: parent.height
                    radius: 3
                    color: theme.white
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(root.percent) + "%"
                font.family: theme.fontMono
                font.pixelSize: 12
                color: theme.textDim
            }
        }
    }
}
