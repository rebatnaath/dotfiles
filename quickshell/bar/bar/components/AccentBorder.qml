import QtQuick

// A thin accent outline for a panel face. Single rectangle with a border;
// the border naturally avoids double-width at corners unlike the old
// four-strip approach. Square by default; cornerRadius rounds the frame.
Rectangle {
    id: frame

    property real thickness: 4 * root.uiScale
    property real cornerRadius: 0
    property color frameColor: root.withAlpha(root.getColor("accent", "#ffb691"), 0.25)

    anchors.fill: parent
    color: "transparent"
    border.width: frame.thickness
    border.color: frame.frameColor
    radius: frame.cornerRadius
}