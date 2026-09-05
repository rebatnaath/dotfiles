import Quickshell
import QtQuick
import QtQuick.Effects

// Shared bar chrome: PanelWindow + rounded face + shadow + border.
// Content injected as default property fills the face.
// Chrome nodes aliased to properties so QML doesn't capture them into content.
// Defaults match fox bar; cat overrides face/border colours.
PanelWindow {
    id: barFace

    // ---- Per-bar knobs --------------------------------------------------
    property real faceHeight: 46 * root.uiScale
    property color faceColor: root.getColor("bg", "#1a120e")
    // accent border
    property color borderColor: root.withAlpha(root.getColor("accent", "#ffb691"), 0.25)
    property real borderThickness: root.barBorderWidth * root.uiScale
    property bool showBorder: root.barBorder
    property bool showShadow: root.barShadow && !root.barFullWidth
    // which screen edge to dock to
    property string side: root.barSide
    // anchor left edge (variants can disable for full-width)
    property bool anchorLeft: true
    // explicit width when anchorLeft is off
    property real faceWidth: -1
    // side margin (0 when full-width)
    property real sideInset: (root.barFullWidth ? 0 : root.barSideMargin) * root.uiScale
    // vertical margins (clear of screen edge)
    property real marginTop: (side === "top" && !root.barFullWidth ? 9 : 0) * root.uiScale
    property real marginBottom: (side === "bottom" && !root.barFullWidth ? 9 : 0) * root.uiScale
    Connections {
        target: root
        function onBarFullWidthChanged() { barFace.refreshMargins() }
        function onUiScaleChanged() { barFace.refreshMargins() }
    }
    function refreshMargins() {
        margins.top = barFace.marginTop
        margins.bottom = barFace.marginBottom
        margins.left = barFace.sideInset
        margins.right = barFace.sideInset
    }

    default property alias content: contentArea.data

    // chrome back-references
    property alias contentLayer: contentArea
    property alias shadowLayer: shadowRect
    property alias faceLayer: face
    property alias borderLayer: border

    // height + shadow room
    implicitHeight: barFace.faceHeight + (barFace.showShadow ? 8 : 0) * root.uiScale
    implicitWidth: barFace.faceWidth
    anchors { left: anchorLeft; right: true; bottom: side === "bottom"; top: side === "top" }
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Auto
    margins {
        top: marginTop
        bottom: marginBottom
        left: sideInset
        right: sideInset
    }
    onSideChanged: refreshMargins()

    Component.onCompleted: refreshMargins()

    // hard offset shadow
    RectangularShadow {
        id: shadowRect
        anchors.fill: face
        radius: root.barCornerRadius * root.uiScale
        color: "#000000"
        blur: 0
        spread: 0
        offset: Qt.vector2d(8 * root.uiScale, 8 * root.uiScale)
        visible: barFace.showShadow
    }

    Rectangle {
        id: face
        height: barFace.faceHeight
        radius: root.barCornerRadius * root.uiScale
        color: barFace.faceColor

        // anchored to trailing edge with shadow gap
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: (barFace.showShadow && !root.barFullWidth ? 8 : 0) * root.uiScale
        anchors.top: barFace.side === "top" ? parent.top : undefined
        anchors.bottom: barFace.side === "bottom" ? parent.bottom : undefined
        anchors.bottomMargin: (barFace.side === "bottom" && barFace.showShadow && !root.barFullWidth ? 8 : 0) * root.uiScale

        // variant content (drawn before border)
        Item {
            id: contentArea
            anchors.fill: parent
        }

        AccentBorder {
            id: border
            cornerRadius: root.barCornerRadius * root.uiScale
            thickness: barFace.borderThickness
            frameColor: barFace.borderColor
            visible: barFace.showBorder
        }
    }
}