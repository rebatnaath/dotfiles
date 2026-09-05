import QtQuick

// Full-width power action row (lock, logout, power off, restart).
Rectangle {
    id: powerActionButton

    property string iconText: ""
    property string labelText: ""
    property real itemRadius: 0
    signal clicked()

    width: parent.width
    height: 60 * root.uiScale
    radius: itemRadius
    color: actionMouse.hovered
        ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.18)
        : root.withAlpha(root.getColor("accent", "#ffb691"), 0.1)
    border.width: 1 * root.uiScale
    border.color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.3)
    Behavior on color { ColorAnimation { duration: 120 } }

    Row {
        anchors.centerIn: parent
        spacing: 10 * root.uiScale

        Text {
            text: powerActionButton.iconText
            font.family: root.fontFamily
            font.pixelSize: 16 * root.uiScale
            color: root.getColor("fg", "#f0dfd8")
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: powerActionButton.labelText
            font.family: root.fontFamily
            font.pixelSize: 13 * root.uiScale
            color: root.getColor("fg", "#f0dfd8")
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: actionMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: powerActionButton.clicked()
    }
}
