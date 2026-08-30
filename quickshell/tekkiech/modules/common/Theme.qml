import QtQuick

// Design tokens, ported from the mockup's monochrome/pitch-black palette
// (see /mockup in the repo root). Plain colors, not oklch() — QML's color
// parser doesn't understand CSS color functions.
QtObject {
    readonly property color bg: "#000000"

    // Frosted panel fill. Use with panelBorder for the glass-panel look;
    // Hyprland's layer-shell blur (decoration.blur in hyprland.conf) is
    // what actually blurs what's behind these, this color just tints it.
    readonly property color surface: Qt.rgba(0.094, 0.094, 0.102, 0.78)
    readonly property color surfaceSoft: Qt.rgba(1, 1, 1, 0.055)

    readonly property color border: Qt.rgba(1, 1, 1, 0.1)
    readonly property color borderStrong: Qt.rgba(1, 1, 1, 0.18)

    readonly property color text: "#f7f7f8"
    readonly property color textDim: "#b3b3b8"
    readonly property color textFaint: "#7a7a80"

    readonly property color white: "#fafafa"
    readonly property color track: Qt.rgba(1, 1, 1, 0.12)

    readonly property string fontSans: "Rubik"
    readonly property string fontMono: "IBM Plex Mono"

    readonly property int radiusSm: 12
    readonly property int radiusMd: 16
    readonly property int radiusLg: 20
}
