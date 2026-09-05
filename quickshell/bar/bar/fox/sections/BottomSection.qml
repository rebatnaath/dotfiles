import Quickshell
import QtQuick

Row {
    id: bottomRow
    spacing: 6 * root.uiScale

    // System group: single "controls" label that opens the quick menu.
    // Scroll wheel adjusts volume.
    Rectangle {
        id: systemBox
        anchors.verticalCenter: parent.verticalCenter
        height: 36 * root.uiScale
        width: systemRow.implicitWidth + 12 * root.uiScale
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.isQuickMenuOpen = !root.isQuickMenuOpen
            onWheel: (event) => {
                if (event.angleDelta.y !== 0 || event.pixelDelta.y !== 0) {
                    root.wheelAccum = Math.max(-600, Math.min(600, root.wheelAccum + event.angleDelta.y))
                    volumeCommitTimer.restart()
                }
                event.accepted = true
            }
        }

        Row {
            id: systemRow
            anchors.centerIn: parent
            spacing: 10 * root.uiScale

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "ctrls"
                font.family: root.fontFamily
                font.pixelSize: 14 * root.uiScale
                color: root.getColor("fg", "#f0dfd8")
            }
        }
    }
}
