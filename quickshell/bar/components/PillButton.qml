import QtQuick

// Reusable pill used for the QuickMenu toggles and actions (wifi, bluetooth,
// dnd, night light, screenshot, battery). isChecked drives the stronger
// "lit up" background; isActive forces foreground text for display-only pills.
Rectangle {
    id: pillButton

    property string iconText: ""
    property string labelText: ""
    property bool isChecked: false
    property bool isActive: false
    property bool iconUsesAccent: false
    property bool isDanger: false
    property int iconPixelSize: 16
    property int labelPixelSize: 12
    signal clicked()

    readonly property color activeForeground: isDanger ? "#ff6b6b" : root.getColor("fg", "#f0dfd8")
    readonly property color activeIconColor: isDanger
        ? "#ff6b6b"
        : (iconUsesAccent ? root.getColor("accent", "#ffb691") : root.getColor("fg", "#f0dfd8"))
    readonly property color inactiveColor: root.withAlpha(root.getColor("muted", "#a08d85"), 0.85)

    width: (parent.width - 20) / 3
    height: 42 * root.uiScale
    radius: 0
    color: isChecked
        ? (pillMouse.hovered
            ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.45)
            : root.withAlpha(root.getColor("accent", "#ffb691"), 0.3))
        : (pillMouse.hovered
            ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.18)
            : root.withAlpha(root.getColor("accent", "#ffb691"), 0.1))
    border.width: 1 * root.uiScale
    border.color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.3)
    Behavior on color { ColorAnimation { duration: 120 } }

    Row {
        anchors.centerIn: parent
        spacing: 8 * root.uiScale

        Text {
            text: pillButton.iconText
            font.family: root.fontFamily
            font.pixelSize: pillButton.iconPixelSize
            color: (pillButton.isChecked || pillButton.isActive)
                ? pillButton.activeIconColor
                : pillButton.inactiveColor
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: pillButton.labelText
            font.family: root.fontFamily
            font.pixelSize: pillButton.labelPixelSize
            width: Math.max(0, pillButton.width - 34)
            elide: Text.ElideRight
            color: (pillButton.isChecked || pillButton.isActive)
                ? pillButton.activeForeground
                : pillButton.inactiveColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: pillMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: pillButton.clicked()
    }
}
