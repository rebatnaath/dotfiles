import Quickshell
import QtQuick

Row {
    id: bottomRow
    spacing: 6

    // System group: single "controls" label that opens the quick menu.
    // Scroll wheel still adjusts volume.
    Rectangle {
        id: systemBox
        anchors.verticalCenter: parent.verticalCenter
        height: 36
        width: systemRow.implicitWidth + 12
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.isQuickMenuOpen = !root.isQuickMenuOpen
        }

        Row {
            id: systemRow
            anchors.centerIn: parent
            spacing: 10

            Text {
                id: controlsLabel
                anchors.verticalCenter: parent.verticalCenter
                text: "ctrls"
                font.family: root.fontFamily
                font.pixelSize: 14 * root.uiScale
                color: root.getColor("fg", "#f0dfd8")

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.isQuickMenuOpen = !root.isQuickMenuOpen
                    onWheel: (event) => {
                        if (event.angleDelta.y !== 0 || event.pixelDelta.y !== 0) {
                            root.wheelAccum += event.angleDelta.y
                            volumeCommitTimer.restart()
                        }
                        event.accepted = true
                    }
                }
            }
        }
    }
}
