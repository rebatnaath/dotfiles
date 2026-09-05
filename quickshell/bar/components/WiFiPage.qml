import Quickshell.Io
import QtQuick
import "../wifi-utils.js" as WifiUtils

// wifi network list page
Column {
    id: wifiColumn
    spacing: 10 * root.uiScale
    width: parent.width
    anchors.horizontalCenter: parent.horizontalCenter

    ListModel { id: wifiModel }

    Process {
        id: wifiListProc
        stdout: StdioCollector { id: wifiListOut; waitForEnd: true; onStreamFinished: WifiUtils.populateModel(wifiModel, wifiListOut.text) }
    }

    Process {
        id: wifiConnectProc
    }

    function refresh() {
        wifiListProc.command = ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "auto"]
        wifiListProc.running = true
    }

    // header row
    Row {
        width: parent.width
        spacing: 8

        Text {
            text: "WiFi Networks"
            font.family: root.fontFamily
            font.pixelSize: 14 * root.uiScale
            font.bold: true
            color: root.getColor("fg", "#f0dfd8")
            anchors.verticalCenter: parent.verticalCenter
        }

        Item { width: parent.width - refreshIcon.width - 100; height: 1 }

        Text {
            id: refreshIcon
            text: "↻"
            font.family: root.fontFamily
            font.pixelSize: 16 * root.uiScale
            color: root.getColor("muted", "#a08d85")
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onClicked: wifiColumn.refresh()
            }
        }
    }

    // network list
    ListView {
        id: wifiList
        width: parent.width
        height: Math.min(contentHeight, 200 * root.uiScale)
        clip: true
        model: wifiModel
        spacing: 4

        delegate: Rectangle {
            width: wifiList.width
            height: 36 * root.uiScale
            radius: root.innerRadius * root.uiScale
            color: model.connected ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.15)
                 : mouseArea.containsMouse ? root.withAlpha(root.getColor("fg", "#f0dfd8"), 0.08)
                 : "transparent"

            Row {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                // signal strength icon
                Text {
                    text: model.signal >= 80 ? "▂▄▆█" : model.signal >= 60 ? "▂▄▆_" : model.signal >= 40 ? "▂▄__" : "▂___"
                    font.family: root.fontFamily
                    font.pixelSize: 12 * root.uiScale
                    color: model.connected ? root.getColor("accent", "#ffb691") : root.getColor("fg", "#f0dfd8")
                    anchors.verticalCenter: parent.verticalCenter
                }

                // ssid
                Text {
                    text: model.ssid
                    font.family: root.fontFamily
                    font.pixelSize: 12 * root.uiScale
                    font.bold: model.connected
                    color: model.connected ? root.getColor("accent", "#ffb691") : root.getColor("fg", "#f0dfd8")
                    elide: Text.ElideRight
                    width: parent.width - signalIcon.width - securityLabel.width - 40
                    anchors.verticalCenter: parent.verticalCenter
                }

                // security indicator
                Text {
                    id: securityLabel
                    text: model.security !== "" ? "🔒" : ""
                    font.pixelSize: 10 * root.uiScale
                    anchors.verticalCenter: parent.verticalCenter
                }

                // connected indicator
                Text {
                    id: signalIcon
                    text: model.connected ? "✓" : ""
                    font.family: root.fontFamily
                    font.pixelSize: 12 * root.uiScale
                    color: root.getColor("accent", "#ffb691")
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!model.connected) {
                        wifiConnectProc.command = ["nmcli", "device", "wifi", "connect", model.ssid]
                        wifiConnectProc.running = true
                        // refresh after connect attempt
                        connectTimer.restart()
                    }
                }
            }
        }
    }

    // refresh after connecting
    Timer {
        id: connectTimer
        interval: 2000
        onTriggered: wifiColumn.refresh()
    }

    onVisibleChanged: if (visible) refresh()
}
