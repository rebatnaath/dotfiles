import Quickshell
import QtQuick

Row {
    id: middleRow
    spacing: 4

    Rectangle {
        id: clockBox
        height: 36
        width: clockRow.implicitWidth + 12
        color: "transparent"

        Row {
            id: clockRow
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.clockShowDate ? root.dateTimeText : root.timeText.substring(0, 2)
                font.family: root.fontFamily
                font.pixelSize: 15 * root.uiScale
                color: root.getColor("fg", "#f0dfd8")
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.clockShowDate
                text: ":"
                font.family: root.fontFamily
                font.pixelSize: 15 * root.uiScale
                color: root.getColor("muted", "#a08d85")
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.clockShowDate
                text: root.timeText.substring(3, 5)
                font.family: root.fontFamily
                font.pixelSize: 15 * root.uiScale
                color: root.getColor("fg", "#f0dfd8")
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: root.isClockHovered = true
            onExited: root.isClockHovered = false
            onClicked: root.clockShowDate = !root.clockShowDate
        }
    }
}
