import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "common"

// App launcher overlay. Toggle with `qs -c tekkiech ipc call launcher toggle`
// (wired to SUPER+R in hypr/hyprland.conf) or the GlobalShortcut below.
// Matches Launcher.dc.html in /mockup: centered glass panel, search + list.
PanelWindow {
    id: launcher

    visible: false
    focusable: visible

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    color: "transparent"
    exclusiveZone: 0

    Theme { id: theme }

    property var results: []

    function refresh(query) {
        const all = [...DesktopEntries.applications.values];
        const q = query.toLowerCase();
        const filtered = q === ""
            ? all
            : all.filter(d =>
                d.name.toLowerCase().includes(q)
                || (d.comment ?? "").toLowerCase().includes(q));
        results = filtered
            .slice()
            .sort((a, b) => a.name.localeCompare(b.name))
            .slice(0, 8);
    }

    function open() {
        visible = true;
        searchField.text = "";
        refresh("");
        searchField.forceActiveFocus();
    }

    function close() {
        visible = false;
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            launcher.visible ? launcher.close() : launcher.open();
        }
    }

    GlobalShortcut {
        name: "launcherToggle"
        description: "Toggle the app launcher"
        onPressed: launcher.visible ? launcher.close() : launcher.open()
    }

    // Scrim — click outside the panel to dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: launcher.close()

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
        }
    }

    Rectangle {
        id: panel
        width: 600
        anchors.horizontalCenter: parent.horizontalCenter
        y: 150
        radius: theme.radiusLg
        color: theme.surface
        border.width: 1
        border.color: theme.borderStrong
        height: headerRow.height + list.height + 20

        // Swallow clicks inside the panel so they don't hit the scrim
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            RowLayout {
                id: headerRow
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                spacing: 12

                TextInput {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    color: theme.text
                    font.family: theme.fontSans
                    font.pixelSize: 15
                    clip: true

                    Text {
                        visible: searchField.text.length === 0
                        text: "Search apps, files, commands…"
                        color: theme.textFaint
                        font: searchField.font
                    }

                    onTextChanged: launcher.refresh(text)
                    Keys.onEscapePressed: launcher.close()
                    Keys.onReturnPressed: {
                        if (results.length > 0) {
                            results[0].execute();
                            launcher.close();
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: theme.border
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(results.length, 1) * 46
                model: results
                spacing: 2
                clip: true

                delegate: Rectangle {
                    required property var modelData
                    width: list.width
                    height: 44
                    radius: theme.radiusSm
                    color: hovered ? theme.surfaceSoft : "transparent"
                    property bool hovered: false

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12

                        Image {
                            source: modelData.icon ? Quickshell.iconPath(modelData.icon) : ""
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            fillMode: Image.PreserveAspectFit
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            color: theme.text
                            font.family: theme.fontSans
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: {
                            modelData.execute();
                            launcher.close();
                        }
                    }
                }
            }
        }
    }
}
