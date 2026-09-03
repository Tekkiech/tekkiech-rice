import QtQuick
import QtQuick.Shapes

// Reusable vector icon, drawn from the same 24x24 stroke-path data as the
// mockup's inline SVGs in /mockup (Main.dc.html etc.) — not a font, not
// an image, so it recolors cleanly via `color` like the mockup's
// currentColor icons did.
Item {
    id: root

    property string name: ""
    property int size: 16
    property color color: "white"
    property real strokeWidth: 1.7

    implicitWidth: size
    implicitHeight: size

    readonly property var strokePaths: ({
        "power": "M12 2v9M18.4 6.6a9 9 0 1 1-12.8 0",
        "wifi": "M3 8.5a16 16 0 0 1 18 0M6.2 12.2a11 11 0 0 1 11.6 0M9.5 15.8a6 6 0 0 1 5 0",
        "bluetooth": "M7 7l10 10-5 5V2l5 5L7 17",
        "mic-off": "M9 9v3a3 3 0 0 0 4.6 2.5M15 9V6a3 3 0 0 0-5.9-.7M19 11a7 7 0 0 1-1.3 4.1M5 11a7 7 0 0 0 9.9 6.4M12 19v3M3 3l18 18",
        "lock": "M6 11h12v9H6zM8 11V7a4 4 0 0 1 8 0v4",
        "restart": "M3.5 12a8.5 8.5 0 1 1 2.8 6.3M3.5 17v-5h5",
        "arrow-right": "M9 6l6 6-6 6",
        "close": "M5 5L19 19M19 5L5 19",
        "volume": "M4 9v6h4l5 4V5L8 9H4zM17 8a6 6 0 0 1 0 8M19.5 5.5a10 10 0 0 1 0 13",
        "brightness-rays": "M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2 2M17.1 17.1l2 2M4.9 19.1l2-2M17.1 6.9l2-2"
    })

    readonly property var fillPaths: ({
        "moon": "M20 13.5A8.5 8.5 0 1 1 10.5 4a6.8 6.8 0 0 0 9.5 9.5z",
        "airplane": "M21 3L3 10.5l7 2.5 2.5 7L21 3z",
        "play": "M6 4l14 8-14 8V4z"
    })

    readonly property bool isFilled: root.fillPaths[root.name] !== undefined
    readonly property string pathData: root.strokePaths[root.name] ?? root.fillPaths[root.name] ?? ""

    Shape {
        width: 24
        height: 24
        scale: root.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.isFilled ? "transparent" : root.color
            fillColor: root.isFilled ? root.color : "transparent"
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg { path: root.pathData }
        }
    }

    // "wifi" and "brightness-rays" pair with a small solid dot in the
    // original mockup (signal dot / sun center) — draw it here so callers
    // don't have to.
    Rectangle {
        visible: root.name === "wifi" || root.name === "brightness-rays"
        anchors.horizontalCenter: parent.horizontalCenter
        // wifi's dot sits low (y=19/24); brightness-rays' sits dead center (y=12/24)
        y: root.size * (root.name === "wifi" ? 19 / 24 : 12 / 24) - height / 2
        width: Math.max(2, root.size * (2 / 24))
        height: width
        radius: width / 2
        color: root.color
    }
}
