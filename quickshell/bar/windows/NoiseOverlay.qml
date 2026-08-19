import Quickshell
import Quickshell.Wayland
import QtQuick

// E-ink / e-paper grain overlay: a full-screen, click-through (mask: Region {})
// layer above every window that tiles a monochrome speckle image so the whole
// desktop reads like a paper display. Intensity follows root.noiseLevel (0 = off,
// 1..5 = density). Like NervFrame, this is a single direct PanelWindow spanning
// the full output so it truly fills the screen (the config runs one monitor).
PanelWindow {
    id: grainFrame

    visible: root.noiseLevel > 0
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    mask: Region {}
    focusable: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // 0..1 density from the 5-level control bundled into the Image opacity.
    readonly property real density: root.noiseLevel > 0 ? (0.25 + 0.75 * (root.noiseLevel - 1) / 4) : 0

    Image {
        anchors.fill: parent
        source: "file:///home/oryza/.config/quickshell/bar/assets/grain.png"
        cache: false
        fillMode: Image.Tile
        asynchronous: false
        opacity: grainFrame.density
    }
}