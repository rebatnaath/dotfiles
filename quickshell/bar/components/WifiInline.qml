import Quickshell.Io
import QtQuick
import "../wifi-utils.js" as WifiUtils

// inline wifi section (expands to show networks)
Column {
    id: wifiSection
    width: parent.width
    spacing: 8 * root.uiScale

    property bool expanded: false
    property string currentSsid: root.wifiName || "Disconnected"
    property bool isConnected: root.wifiName !== ""

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

    // header (always visible)
    Rectangle {
        width: parent.width
        height: 32 * root.uiScale
        radius: root.innerRadius * root.uiScale
        color: wifiSection.expanded ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.12) : "transparent"

        Row {
            anchors.fill: parent
            anchors.margins: 4 * root.uiScale
            spacing: 8

            // wifi icon
            Text {
                text: root.wifiName === "" ? "󰖪" : "󰖩"
                font.family: root.fontFamily
                font.pixelSize: 14 * root.uiScale
                color: root.wifiName !== "" ? root.getColor("accent", "#ffb691") : root.getColor("muted", "#a08d85")
                anchors.verticalCenter: parent.verticalCenter
            }

            // status text
            Text {
                text: root.isWifiConnecting ? "Connecting…" : wifiSection.currentSsid
                font.family: root.fontFamily
                font.pixelSize: 12 * root.uiScale
                color: root.getColor("fg", "#f0dfd8")
                elide: Text.ElideRight
                width: parent.width - expandArrow.width - 40
                anchors.verticalCenter: parent.verticalCenter
            }

            // expand arrow
            Text {
                id: expandArrow
                text: wifiSection.expanded ? "▲" : "▼"
                font.family: root.fontFamily
                font.pixelSize: 10 * root.uiScale
                color: root.getColor("muted", "#a08d85")
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                wifiSection.expanded = !wifiSection.expanded
                if (wifiSection.expanded) wifiSection.refresh()
            }
        }
    }

    // network list (shown when expanded)
    ListView {
        id: wifiList
        width: parent.width
        height: wifiSection.expanded ? Math.min(contentHeight, 150 * root.uiScale) : 0
        clip: true
        model: wifiModel
        spacing: 2
        visible: wifiSection.expanded
        opacity: wifiSection.expanded ? 1 : 0

        Behavior on height { NumberAnimation { duration: 150 } }
        Behavior on opacity { NumberAnimation { duration: 150 } }

        delegate: Rectangle {
            width: wifiList.width
            height: 28 * root.uiScale
            radius: root.innerRadius * root.uiScale
            color: model.connected ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.15)
                 : networkMouse.containsMouse ? root.withAlpha(root.getColor("fg", "#f0dfd8"), 0.08)
                 : "transparent"

            Row {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 6

                // signal bars
                Text {
                    text: model.signal >= 80 ? "▂▄▆█" : model.signal >= 60 ? "▂▄▆_" : model.signal >= 40 ? "▂▄__" : "▂___"
                    font.family: root.fontFamily
                    font.pixelSize: 10 * root.uiScale
                    color: model.connected ? root.getColor("accent", "#ffb691") : root.getColor("muted", "#a08d85")
                    anchors.verticalCenter: parent.verticalCenter
                }

                // ssid
                Text {
                    text: model.ssid
                    font.family: root.fontFamily
                    font.pixelSize: 11 * root.uiScale
                    font.bold: model.connected
                    color: model.connected ? root.getColor("accent", "#ffb691") : root.getColor("fg", "#f0dfd8")
                    elide: Text.ElideRight
                    width: parent.width - 80
                    anchors.verticalCenter: parent.verticalCenter
                }

                // security + connected
                Text {
                    text: (model.security !== "" ? "🔒 " : "") + (model.connected ? "✓" : "")
                    font.pixelSize: 9 * root.uiScale
                    color: root.getColor("muted", "#a08d85")
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: networkMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!model.connected) {
                        wifiConnectProc.command = ["nmcli", "device", "wifi", "connect", model.ssid]
                        wifiConnectProc.running = true
                        connectRetry.restart()
                    }
                }
            }
        }
    }

    // retry connection status
    Timer {
        id: connectRetry
        interval: 2000
        onTriggered: {
            root.pollWifi()
            wifiSection.refresh()
        }
    }

    onVisibleChanged: if (visible && expanded) refresh()
}
