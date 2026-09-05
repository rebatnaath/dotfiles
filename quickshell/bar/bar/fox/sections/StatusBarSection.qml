import Quickshell
import QtQuick

// Status bar: shows wifi, volume, battery as clickable pills.
// Each pill opens the quick menu when clicked.
Row {
    id: statusRow
    spacing: 6 * root.uiScale

    function toggleQuickMenu() { root.isQuickMenuOpen = !root.isQuickMenuOpen }

    // wifi
    Rectangle {
        height: 36 * root.uiScale
        width: wifiRow.implicitWidth + 12 * root.uiScale
        color: "transparent"

        Row {
            id: wifiRow
            anchors.centerIn: parent
            spacing: 4 * root.uiScale

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.wifiEnabled ? "󰤨" : "󰤭"
                font.family: "Symbols Only Nerd Font"
                font.pixelSize: 13 * root.uiScale
                color: root.getColor("fg", "#f0dfd8")
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.wifiEnabled ? (root.wifiName || "---") : "off"
                font.family: root.fontFamily
                font.pixelSize: 12 * root.uiScale
                color: root.getColor("fg", "#f0dfd8")
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: statusRow.toggleQuickMenu()
        }
    }

    // volume
    Rectangle {
        height: 36 * root.uiScale
        width: volRow.implicitWidth + 12 * root.uiScale
        color: "transparent"

        Row {
            id: volRow
            anchors.centerIn: parent
            spacing: 4 * root.uiScale

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.isVolumeMuted ? "󰝟" : root.volume >= 70 ? "󰕾" : root.volume >= 30 ? "󰖀" : "󰕿"
                font.family: "Symbols Only Nerd Font"
                font.pixelSize: 13 * root.uiScale
                color: root.getColor("fg", "#f0dfd8")
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.volume >= 0 ? root.volume + "%" : "--"
                font.family: root.fontFamily
                font.pixelSize: 12 * root.uiScale
                color: root.getColor("fg", "#f0dfd8")
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: statusRow.toggleQuickMenu()
            onWheel: (event) => {
                if (event.angleDelta.y !== 0 || event.pixelDelta.y !== 0) {
                    root.wheelAccum = Math.max(-600, Math.min(600, root.wheelAccum + event.angleDelta.y))
                    volumeCommitTimer.restart()
                }
                event.accepted = true
            }
        }
    }

    // battery
    Rectangle {
        height: 36 * root.uiScale
        width: batRow.implicitWidth + 12 * root.uiScale
        color: "transparent"

        Row {
            id: batRow
            anchors.centerIn: parent
            spacing: 4 * root.uiScale

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.batteryLevel < 0 ? "󰂑" : root.batteryStatus === "Charging" ? "󰢜" : "󰁹"
                font.family: "Symbols Only Nerd Font"
                font.pixelSize: 13 * root.uiScale
                color: root.getColor("fg", "#f0dfd8")
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.batteryLevel >= 0 ? root.batteryLevel + "%" : "--"
                font.family: root.fontFamily
                font.pixelSize: 12 * root.uiScale
                color: root.getColor("fg", "#f0dfd8")
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: statusRow.toggleQuickMenu()
        }
    }
}
