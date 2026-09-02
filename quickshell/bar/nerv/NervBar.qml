import Quickshell
import QtQuick
import QtQuick.Effects
import "../components"
import "sections"

// The nerv bar, matched to the NERV-bar mockup: a black face with a 3px red
// border, angel workspaces on the left, and a red "ANGELS ZONE" label on the
// right. No clock/system group, mirroring index.html.
PanelWindow {
    id: nervBar
    anchors { left: true; right: true; bottom: root.barSide === "bottom"; top: root.barSide === "top" }
    // 60px face. Window slightly larger to leave breathing room; no shadow.
    implicitHeight: 68 * root.uiScale
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Auto

    // Float the bar inset from the screen edges so it sits clear of the NERV
    // frame, with a visible top/bottom gap and generous side margins.
    margins {
        top: (root.barSide === "top" ? 16 : 0) * root.uiScale
        bottom: (root.barSide === "bottom" ? 26 : 0) * root.uiScale
        // Nerv is a fixed theme: it ignores the shared barFullWidth option and
        // always keeps its inset side margins.
        left: (root.barSideMargin - 120) * root.uiScale
        right: (root.barSideMargin - 120) * root.uiScale
    }

    // NERV bar has no drop shadow (the frame handles the look), so this stays
    // off regardless of the rice's barShadow setting.
    RectangularShadow {
        anchors.fill: face
        radius: 0
        color: "#000000"
        blur: 0
        spread: 0
        offset: root.barSide === "top" ? Qt.vector2d(8, -8) : Qt.vector2d(8, 8)
        visible: false
    }

    Rectangle {
        id: face
        height: 60 * root.uiScale
        radius: root.frameRadius
        color: "#000000"

        // No shadow, so the face hugs the screen edge and spans full width.
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: 8 * root.uiScale
        anchors.top: root.barSide === "top" ? parent.top : undefined
        anchors.bottom: root.barSide === "bottom" ? parent.bottom : undefined

        // 3px red border matching the mockup's `border: 3px solid #9D0A12`.
        // Always drawn — the border is part of the nerv identity, not opting into
        // the shared barBorder toggle.
        AccentBorder {
            thickness: 3 * root.uiScale
            cornerRadius: root.frameRadius
            frameColor: "#9D0A12"
            visible: true
        }

        // Angel workspaces fill the left side; ANGELS ZONE label the right.
        TopSection {
            id: topSection
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        ZoneSection {
            id: zoneSection
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}