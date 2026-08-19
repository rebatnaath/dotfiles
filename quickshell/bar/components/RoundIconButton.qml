import QtQuick

// Circular media-control button (play/pause, next): transparent resting state
// with an accent ring + fill that appear on hover.
Rectangle {
    id: roundIconButton

    property string iconText: ""
    signal clicked()

    width: 34 * root.uiScale
    height: 34 * root.uiScale
    radius: 17
    color: roundIconButtonMouse.hovered
        ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.14)
        : "transparent"
    border.width: roundIconButtonMouse.hovered ? 1 : 0
    border.color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.4)
    scale: roundIconButtonMouse.pressed ? 0.9 : 1
    Behavior on scale { NumberAnimation { duration: 100 } }
    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        anchors.centerIn: parent
        text: roundIconButton.iconText
        font.family: root.fontFamily
        font.pixelSize: 15 * root.uiScale
        color: root.getColor("accent", "#ffb691")
    }

    MouseArea {
        id: roundIconButtonMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: roundIconButton.clicked()
    }
}