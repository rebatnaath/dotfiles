import QtQuick

// A thin accent outline for a panel face. Four strips (verticals cover the
// corners, horizontals sit between) so the semi-transparent frame doesn't
// double up at the corner overlap. Square by default; cornerRadius rounds the
// frame for the rounded variant (must match the parent face's radius).
Item {
    id: frame

    property real thickness: 4 * root.uiScale
    property real cornerRadius: 0

    // Defaults to a translucent accent; callers (e.g. the lonely bar) may
    // override it to match their face colour. In nerv mode the accent border is
    // solid so it matches the bar/frame/window borders' solid red.
    property color frameColor: root.activeBar === "nerv"
        ? root.getColor("accent", "#ffb691")
        : root.withAlpha(root.getColor("accent", "#ffb691"), 0.25)

    anchors.fill: parent

    Rectangle { x: 0; y: 0; width: frame.thickness; height: parent.height; radius: frame.cornerRadius; color: frame.frameColor }
    Rectangle { x: parent.width - frame.thickness; y: 0; width: frame.thickness; height: parent.height; radius: frame.cornerRadius; color: frame.frameColor }
    Rectangle { x: frame.thickness; y: 0; width: parent.width - 2 * frame.thickness; height: frame.thickness; radius: frame.cornerRadius; color: frame.frameColor }
    Rectangle { x: frame.thickness; y: parent.height - frame.thickness; width: parent.width - 2 * frame.thickness; height: frame.thickness; radius: frame.cornerRadius; color: frame.frameColor }
}