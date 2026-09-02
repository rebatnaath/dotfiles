import Quickshell
import QtQuick
import QtQuick.Effects

// Shared bar chrome: the floating PanelWindow + rounded face + hard offset
// shadow + accent border that every bar variant uses, with per-bar colour /
// size knobs. Bar-specific content is injected as the default property (child
// objects) and fills the face, so each variant only describes its own layout.
//
// NOTE: the chrome nodes (content/face/shadow/border) are each assigned to a
// property alias below purely so QML's default-property collector does not
// capture them into the content area; only genuine variant content ends up as
// children.
//
// Defaults match the fox bar. The lonely bar overrides the face/border colours;
// the nerv bar keeps its own file because its fixed inset margins, no-shadow
// look and always-on 3px red border are genuinely a different layout.
PanelWindow {
    id: barFace

    // ---- Per-bar knobs --------------------------------------------------
    property real faceHeight: 46 * root.uiScale
    property color faceColor: root.getColor("bg", "#1a120e")
    // Translucent accent outline (matches fox). Lonely overrides to a solid
    // face-colour ring.
    property color borderColor: root.withAlpha(root.getColor("accent", "#ffb691"), 0.25)
    property real borderThickness: 4 * root.uiScale
    property bool showBorder: root.barBorder
    property bool showShadow: root.barShadow && !root.barFullWidth
    // Which screen edge the bar docks to; a variant can pin its own side
    // independent of the global barSide setting.
    property string side: root.barSide
    // Anchor the left edge. Variants that must span the true full width
    // turn this off and set faceWidth instead.
    property bool anchorLeft: true
    // Explicit window width when anchorLeft is off (-1 = stretch to anchors).
    property real faceWidth: -1
    // Side margin: floats the bar inset from the screen edge (kept even with
    // the shadow off); full-width mode sits flush against the edge.
    property real sideInset: root.barFullWidth ? 0 : root.barSideMargin
    // Vertical margins: clear of the screen edge when not full-width.
    property real marginTop: (side === "top" && !root.barFullWidth ? 9 : 0) * root.uiScale
    property real marginBottom: (side === "bottom" && !root.barFullWidth ? 9 : 0) * root.uiScale

    default property alias content: contentArea.data

    // Chrome back-references that keep the internals out of `content` (see note).
    property alias contentLayer: contentArea
    property alias shadowLayer: shadowRect
    property alias faceLayer: face
    property alias borderLayer: border

    // Face height + 8px shadow room when one is shown.
    implicitHeight: barFace.faceHeight + (barFace.showShadow ? 8 : 0) * root.uiScale
    implicitWidth: barFace.faceWidth
    anchors { left: anchorLeft; right: true; bottom: side === "bottom"; top: side === "top" }
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Auto
    margins {
        top: marginTop
        bottom: marginBottom
        left: sideInset * root.uiScale
        right: sideInset * root.uiScale
    }

    Component.onCompleted: {
        root.barHeight = barFace.faceHeight
        root.barEdge = barFace.faceHeight + (barFace.side === "top" ? barFace.marginTop : barFace.marginBottom)
    }

    // Hard offset shadow cast toward the trailing edge: below the bar at the
    // bottom, above it at the top. The face is inset from that edge so the
    // shadow has room to show.
    RectangularShadow {
        id: shadowRect
        anchors.fill: face
        radius: 0
        color: "#000000"
        blur: 0
        spread: 0
        offset: barFace.side === "top" ? Qt.vector2d(8 * root.uiScale, -8 * root.uiScale) : Qt.vector2d(8 * root.uiScale, 8 * root.uiScale)
        visible: barFace.showShadow
    }

    Rectangle {
        id: face
        height: barFace.faceHeight
        radius: root.frameRadius
        color: barFace.faceColor

        // Anchored to the trailing edge with an 8px gap for the shadow when
        // one is shown; flush otherwise.
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: (barFace.showShadow && !root.barFullWidth ? 8 : 0) * root.uiScale
        anchors.top: barFace.side === "top" ? parent.top : undefined
        anchors.topMargin: (barFace.side === "top" && barFace.showShadow && !root.barFullWidth ? 8 : 0) * root.uiScale
        anchors.bottom: barFace.side === "bottom" ? parent.bottom : undefined
        anchors.bottomMargin: (barFace.side === "bottom" && barFace.showShadow && !root.barFullWidth ? 8 : 0) * root.uiScale

        // Bar-unique content. Drawn before the border ring so a variant that
        // extends fills to the face edges (e.g. lonely) still shows the border
        // on top, exactly like the non-shared bars did.
        Item {
            id: contentArea
            anchors.fill: parent
        }

        AccentBorder {
            id: border
            cornerRadius: root.frameRadius
            thickness: barFace.borderThickness
            frameColor: barFace.borderColor
            visible: barFace.showBorder
        }
    }
}