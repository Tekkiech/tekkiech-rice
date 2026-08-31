import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "common"

// Matches Notifications.dc.html in /mockup: a top-right toast stack.
// NotificationServer delivers a signal per notification rather than a
// bindable list, so this keeps its own array and times entries out
// itself (using the notification's own expireTimeout when it set one).
PanelWindow {
    id: root

    anchors {
        top: true
        right: true
    }
    implicitWidth: 340
    implicitHeight: Math.max(screen.height, 1)
    color: "transparent"
    exclusiveZone: 0
    focusable: false

    Theme { id: theme }

    property var toasts: []

    NotificationServer {
        id: server

        onNotification: notification => {
            notification.tracked = true;
            const entry = { n: notification, id: notification.id };
            root.toasts = [entry, ...root.toasts].slice(0, 5);

            const timeoutMs = notification.expireTimeout > 0 ? notification.expireTimeout : 6000;
            const t = timerComponent.createObject(root, { targetId: notification.id, interval: timeoutMs });
            t.triggered.connect(() => root.dismiss(notification.id));
        }
    }

    function dismiss(id) {
        const entry = root.toasts.find(e => e.id === id);
        if (entry) entry.n.dismiss();
        root.toasts = root.toasts.filter(e => e.id !== id);
    }

    Component {
        id: timerComponent
        Timer {
            property int targetId
            running: true
            repeat: false
        }
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 20
        spacing: 12
        width: 300

        Repeater {
            model: root.toasts
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: content.implicitHeight + 28
                radius: theme.radiusMd
                color: theme.surface
                border.width: 1
                border.color: theme.borderStrong

                RowLayout {
                    id: content
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        Layout.alignment: Qt.AlignTop
                        radius: 10
                        color: theme.surfaceSoft

                        Image {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            visible: modelData.n.appIcon !== ""
                            source: modelData.n.appIcon !== "" ? Quickshell.iconPath(modelData.n.appIcon) : ""
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: modelData.n.summary
                                font.family: theme.fontSans
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: theme.text
                                elide: Text.ElideRight
                            }
                            Text {
                                text: "✕"
                                font.pixelSize: 11
                                color: theme.textFaint
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.dismiss(modelData.n.id)
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: modelData.n.body !== ""
                            text: modelData.n.body
                            font.family: theme.fontSans
                            font.pixelSize: 12.5
                            color: theme.textDim
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
