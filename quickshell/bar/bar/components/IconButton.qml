import QtQuick

// square icon button with accent tint
Rectangle {
    id: iconButton

    property string iconText: ""
    property string iconFontFamily: root.fontFamily
    property int iconPixelSize: 18
    property bool isActive: false
    property real buttonRadius: 0
    signal clicked()

    width: 36 * root.uiScale
    height: 36 * root.uiScale
    radius: buttonRadius
    color: (iconButtonMouse.hovered || isActive)
        ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.24)
        : root.withAlpha(root.getColor("accent", "#ffb691"), 0.14)
    border.width: 1 * root.uiScale
    border.color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.4)
    scale: iconButtonMouse.pressed ? 0.9 : 1
    Behavior on scale { NumberAnimation { duration: 100 } }
    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        anchors.centerIn: parent
        text: iconButton.iconText
        font.family: iconButton.iconFontFamily
        font.pixelSize: iconButton.iconPixelSize
        color: root.getColor("fg", "#f0dfd8")
    }

    MouseArea {
        id: iconButtonMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: iconButton.clicked()
    }
}
