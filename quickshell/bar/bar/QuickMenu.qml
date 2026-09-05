import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import "components"

PanelWindow {
    id: menuWindow
    color: "transparent"
    aboveWindows: true
    focusable: true
    visible: root.isQuickMenuOpen
    anchors { top: true; left: true; right: true; bottom: true }
    margins { top: 0; bottom: 0; left: 0; right: 0 }
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore

    onVisibleChanged: {
        if (!visible) {
            wifiNetworksColumn.visible = false
            bluetoothDevicesColumn.visible = false
        }
    }


    // card geometry
    readonly property int cardTopPadding: Math.round(17 * root.uiScale)
    readonly property int profileHeaderHeight: Math.round(48 * root.uiScale)
    readonly property int menuColumnSpacing: Math.round(16 * root.uiScale)
    readonly property int dividerHeight: Math.round(1 * root.uiScale)
    readonly property int cardBottomPadding: Math.round(14 * root.uiScale)
    // chrome height (everything except content)
    readonly property int chromeHeight: cardTopPadding + profileHeaderHeight
        + menuColumnSpacing + dividerHeight + menuColumnSpacing + cardBottomPadding

    Process {
        id: screenshotProc
    }

    // toggle page, close others
    function togglePage(pageName) {
        var pageProperty = "is" + pageName + "PageOpen"
        var wasOpen = root[pageProperty]
        root.closeAllPages()
        if (!wasOpen) {
            root[pageProperty] = true
        }
    }

    // click outside closes menu
    MouseArea {
        anchors.fill: parent
        onClicked: root.isQuickMenuOpen = false
    }

    // shadow
    RectangularShadow {
        anchors.fill: menuCard
        radius: root.quickMenuCornerRadius * root.uiScale
        color: "#000000"
        blur: 0
        spread: 0
        offset: Qt.vector2d(8 * root.uiScale, 8 * root.uiScale)
        visible: root.quickMenuShadow
    }

    // primary screen (multi-monitor not supported)
    readonly property var screen: root.safeScreen

    Rectangle {
        id: menuCard
        clip: true
        // align card with bar face right edge; QM shadow extends 8px right to bar shadow edge
        // bar face has rightMargin 8 when bar shadow is on; match it
        readonly property real rightMargin: (root.barShadow && !root.barFullWidth ? 8 : 0) * root.uiScale
        // bar uses barSideMargin * uiScale for its margins; match that
        readonly property real sideMargin: root.barSideMargin * root.uiScale
        x: root.barFullWidth ? menuWindow.screen.width - menuCard.width - menuCard.rightMargin
                             : menuWindow.screen.width - menuCard.sideMargin - menuCard.width - menuCard.rightMargin
        // below bar (top) or above bar (bottom)
        y: root.barSide === "top" ? 6 * root.uiScale : Math.max(0, menuWindow.height - menuCard.height - 6 * root.uiScale)
        width: 400 * root.uiScale
        height: chromeHeight + Math.max(
            systemControlsColumn.visible ? systemControlsColumn.height : 0,
            powerPageColumn.visible ? powerPageColumn.height : 0,
            notifPageColumn.visible ? notifPageColumn.height : 0,
            clipPageColumn.visible ? clipPageColumn.height : 0,
            settingsPageColumn.visible ? settingsPageColumn.height : 0
        )
        radius: root.quickMenuCornerRadius * root.uiScale
        color: root.getColor("bg", "#1a120e")

        AccentBorder {
            cornerRadius: root.quickMenuCornerRadius * root.uiScale
            thickness: root.quickMenuBorderWidth * root.uiScale
            visible: root.quickMenuBorder
        }

        // consume clicks on card
        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => mouse.accepted = true
        }

        Column {
            id: menuColumn
            anchors.top: parent.top
            anchors.topMargin: cardTopPadding
            anchors.horizontalCenter: parent.horizontalCenter
            width: 366 * root.uiScale
            spacing: menuColumnSpacing

            ProfileHeader {
                itemRadius: root.quickMenuInnerRadius * root.uiScale
                onNotificationsRequested: menuWindow.togglePage("Notification")
                onClipboardRequested: menuWindow.togglePage("Clipboard")
                onSettingsRequested: menuWindow.togglePage("Settings")
                onPowerMenuRequested: menuWindow.togglePage("Power")
                onScreenshotRequested: {
                    root.isQuickMenuOpen = false
                    screenshotProc.command = ["bash", "-c", "mkdir -p \"$HOME/Pictures/Screenshots/sway\" && REGION=\"$(slurp)\" && [ -n \"$REGION\" ] && grim -g \"$REGION\" - | tee \"$HOME/Pictures/Screenshots/sway/screenshot-$(date +%Y-%m-%d_%H%M%S).png\" | wl-copy"]
                    screenshotProc.startDetached()
                }
                onCaffeineRequested: root.toggleCaffeine()
            }

            Divider {}

            // system controls
            Column {
                id: systemControlsColumn
                spacing: menuColumnSpacing
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !root.isPowerPageOpen && !root.isNotificationPageOpen && !root.isClipboardPageOpen && !root.isSettingsPageOpen

                Row {
                    spacing: 10 * root.uiScale
                    width: parent.width
                    anchors.horizontalCenter: parent.horizontalCenter

                    // wifi pill with arrow
                    Rectangle {
                        id: wifiPill
                        width: (parent.width - 20) / 3
                        height: 42 * root.uiScale
                        radius: root.quickMenuInnerRadius * root.uiScale
                        color: root.wifiName !== ""
                            ? (wifiPillMouse.containsMouse
                                ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.45)
                                : root.withAlpha(root.getColor("accent", "#ffb691"), 0.3))
                            : (wifiPillMouse.containsMouse
                                ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.18)
                                : root.withAlpha(root.getColor("accent", "#ffb691"), 0.1))
                        border.width: 1 * root.uiScale
                        border.color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.3)

                        Row {
                            anchors.centerIn: parent
                            spacing: 8 * root.uiScale

                            Text {
                                text: root.wifiName === "" ? "󰖪" : "󰖩"
                                font.family: root.fontFamily
                                font.pixelSize: 16
                                color: root.wifiName !== "" ? root.getColor("accent", "#ffb691") : root.getColor("muted", "#a08d85")
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.isWifiConnecting ? "Connecting…" : (root.wifiName === "" ? "Disconnected" : root.wifiName)
                                font.family: root.fontFamily
                                font.pixelSize: 12
                                width: wifiPill.width - 50
                                elide: Text.ElideRight
                                color: root.wifiName !== "" ? root.getColor("fg", "#f0dfd8") : root.getColor("muted", "#a08d85")
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // toggle wifi on click
                        MouseArea {
                            id: wifiPillMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.toggleWifi()
                                wifiNetworksColumn.visible = false
                            }
                        }

                        // arrow button on right
                        Rectangle {
                            id: wifiArrow
                            width: 20 * root.uiScale
                            height: parent.height
                            anchors.right: parent.right
                            color: wifiArrowMouse.containsMouse
                                ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.3)
                                : "transparent"
                            opacity: root.wifiEnabled ? 1 : 0.3

                            Text {
                                text: wifiNetworksColumn.visible ? "▲" : "▼"
                                font.family: root.fontFamily
                                font.pixelSize: 10
                                color: root.getColor("muted", "#a08d85")
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: wifiArrowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!root.wifiEnabled) return
                                    wifiNetworksColumn.visible = !wifiNetworksColumn.visible
                                    if (wifiNetworksColumn.visible) {
                                        bluetoothDevicesColumn.visible = false
                                        wifiNetworksColumn.refresh()
                                    }
                                }
                            }
                        }
                    }

                    // bluetooth pill with arrow
                    Rectangle {
                        id: bluetoothPill
                        width: (parent.width - 20) / 3
                        height: 42 * root.uiScale
                        radius: root.quickMenuInnerRadius * root.uiScale
                        color: root.bluetoothEnabled
                            ? (bluetoothPillMouse.containsMouse
                                ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.45)
                                : root.withAlpha(root.getColor("accent", "#ffb691"), 0.3))
                            : (bluetoothPillMouse.containsMouse
                                ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.18)
                                : root.withAlpha(root.getColor("accent", "#ffb691"), 0.1))
                        border.width: 1 * root.uiScale
                        border.color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.3)

                        Row {
                            anchors.centerIn: parent
                            spacing: 8 * root.uiScale

                            Text {
                                text: root.bluetoothEnabled ? "󰂯" : "󰂲"
                                font.family: root.fontFamily
                                font.pixelSize: 16
                                color: root.bluetoothEnabled ? root.getColor("accent", "#ffb691") : root.getColor("muted", "#a08d85")
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.isBluetoothConnecting ? "Connecting…" : (root.bluetoothEnabled ? (root.bluetoothDeviceName === "" ? "On" : root.bluetoothDeviceName) : "Off")
                                font.family: root.fontFamily
                                font.pixelSize: 12
                                width: bluetoothPill.width - 50
                                elide: Text.ElideRight
                                color: root.bluetoothEnabled ? root.getColor("fg", "#f0dfd8") : root.getColor("muted", "#a08d85")
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // toggle bluetooth on click
                        MouseArea {
                            id: bluetoothPillMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.toggleBluetooth()
                                bluetoothDevicesColumn.visible = false
                            }
                        }

                        // arrow button on right
                        Rectangle {
                            id: bluetoothArrow
                            width: 20 * root.uiScale
                            height: parent.height
                            anchors.right: parent.right
                            color: bluetoothArrowMouse.containsMouse
                                ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.3)
                                : "transparent"
                            opacity: root.bluetoothEnabled ? 1 : 0.3

                            Text {
                                text: bluetoothDevicesColumn.visible ? "▲" : "▼"
                                font.family: root.fontFamily
                                font.pixelSize: 10
                                color: root.getColor("muted", "#a08d85")
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: bluetoothArrowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!root.bluetoothEnabled) return
                                    bluetoothDevicesColumn.visible = !bluetoothDevicesColumn.visible
                                    if (bluetoothDevicesColumn.visible) {
                                        wifiNetworksColumn.visible = false
                                        bluetoothDevicesColumn.refresh()
                                    }
                                }
                            }
                        }
                    }

                    PillButton {
                        iconText: root.isDndEnabled ? "󰂛" : "󰂝"
                        labelText: root.isDndEnabled ? "DND On" : "DND Off"
                        isChecked: root.isDndEnabled
                        pillRadius: root.quickMenuInnerRadius * root.uiScale
                        iconUsesAccent: true
                        onClicked: root.toggleDnd()
                    }
                }

                // bluetooth devices list (below the pills)
                Rectangle {
                    id: bluetoothDevicesColumn
                    width: parent.width
                    height: visible ? Math.max(140 * root.uiScale, Math.min(bluetoothDevicesColumn.headerHeight + bluetoothDevicesList.contentHeight + 24, 340 * root.uiScale)) : 0
                    visible: false
                    clip: true
                    color: root.withAlpha(root.getColor("bg", "#1a120e"), 0.95)
                    radius: root.quickMenuInnerRadius * root.uiScale
                    border.width: 1 * root.uiScale
                    border.color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.2)

                    readonly property int headerHeight: 28 * root.uiScale

                    Behavior on height { NumberAnimation { duration: 150 } }

                    property var devicesModel: ListModel { id: bluetoothDevicesModel }

                    function refresh() {
                        bluetoothListProc.running = true
                    }

                    function pairDevice(mac) {
                        bluetoothActionProc.command = ["bluetoothctl", "pair", mac]
                        bluetoothActionProc.running = true
                        bluetoothRetryTimer.restart()
                    }

                    function connectDevice(mac) {
                        bluetoothActionProc.command = ["bluetoothctl", "connect", mac]
                        bluetoothActionProc.running = true
                        bluetoothRetryTimer.restart()
                    }

                    function disconnectDevice(mac) {
                        bluetoothActionProc.command = ["bluetoothctl", "disconnect", mac]
                        bluetoothActionProc.running = true
                        bluetoothRetryTimer.restart()
                    }

                    function removeDevice(mac) {
                        bluetoothActionProc.command = ["bluetoothctl", "remove", mac]
                        bluetoothActionProc.running = true
                        bluetoothRetryTimer.restart()
                    }

                    Process {
                        id: bluetoothListProc
                        command: ["bluetoothctl", "devices"]
                        stdout: StdioCollector { id: bluetoothListOut; waitForEnd: true; onStreamFinished: {
                            var entries = []
                            var lines = bluetoothListOut.text.split("\n")
                            for (var i = 0; i < lines.length; i++) {
                                var line = lines[i].trim()
                                if (line === "" || !line.startsWith("Device")) continue
                                var parts = line.split(" ")
                                if (parts.length < 3) continue
                                var mac = parts[1]
                                var name = parts.slice(2).join(" ")
                                entries.push({
                                    mac: mac,
                                    name: name,
                                    connected: false,
                                    paired: false
                                })
                            }
                            bluetoothDevicesColumn.devicesModel.clear()
                            for (var k = 0; k < entries.length; k++) {
                                bluetoothDevicesColumn.devicesModel.append(entries[k])
                            }
                        }}
                    }

                    Process {
                        id: bluetoothActionProc
                    }

                    // header row
                    Item {
                        id: bluetoothHeader
                        width: parent.width - 16
                        height: bluetoothDevicesColumn.headerHeight
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            text: "Bluetooth"
                            font.family: root.fontFamily
                            font.pixelSize: 12 * root.uiScale
                            font.bold: true
                            color: root.getColor("fg", "#f0dfd8")
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: 24 * root.uiScale
                            height: 24 * root.uiScale
                            radius: root.quickMenuInnerRadius * root.uiScale
                            color: bluetoothScanMouse.containsMouse
                                ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.2)
                                : "transparent"
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "↻"
                                font.family: root.fontFamily
                                font.pixelSize: 14 * root.uiScale
                                color: root.getColor("muted", "#a08d85")
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: bluetoothScanMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    bluetoothScanProc.command = ["bluetoothctl", "scan", "on"]
                                    bluetoothScanProc.running = true
                                    scanTimeout.restart()
                                }
                            }
                        }
                    }

                    // divider
                    Rectangle {
                        width: parent.width - 16
                        height: 1
                        anchors.top: bluetoothHeader.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.15)
                    }

                    // devices list
                    ListView {
                        id: bluetoothDevicesList
                        width: parent.width
                        anchors.top: bluetoothHeader.bottom
                        anchors.topMargin: 8
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 8
                        clip: true
                        model: bluetoothDevicesColumn.devicesModel
                        spacing: 4

                        // empty state
                        Text {
                            anchors.centerIn: parent
                            text: bluetoothListProc.running ? "Scanning devices..." : (root.bluetoothEnabled ? "No devices found" : "Bluetooth is off")
                            font.family: root.fontFamily
                            font.pixelSize: 11 * root.uiScale
                            color: root.getColor("muted", "#a08d85")
                            visible: bluetoothDevicesList.count === 0
                        }

                        delegate: Rectangle {
                            width: bluetoothDevicesList.width
                            height: 32 * root.uiScale
                            radius: root.quickMenuInnerRadius * root.uiScale
                            color: btMouse.containsMouse ? root.withAlpha(root.getColor("fg", "#f0dfd8"), 0.08) : "transparent"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 2

                                Text {
                                    text: model.name
                                    font.family: root.fontFamily
                                    font.pixelSize: 11 * root.uiScale
                                    color: root.getColor("fg", "#f0dfd8")
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: model.mac
                                    font.family: root.fontFamily
                                    font.pixelSize: 8 * root.uiScale
                                    color: root.getColor("muted", "#a08d85")
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            MouseArea {
                                id: btMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    // try connect, if fails pair then connect
                                    bluetoothDevicesColumn.connectDevice(model.mac)
                                }
                            }
                        }
                    }

                    Timer {
                        id: scanTimeout
                        interval: 10000
                        onTriggered: {
                            bluetoothScanProc.command = ["bluetoothctl", "scan", "off"]
                            bluetoothScanProc.running = true
                            bluetoothDevicesColumn.refresh()
                        }
                    }

                    Process {
                        id: bluetoothScanProc
                    }

                    Timer {
                        id: bluetoothRetryTimer
                        interval: 2000
                        onTriggered: bluetoothDevicesColumn.refresh()
                    }
                }

                // wifi networks list (below the pills)
                Rectangle {
                    id: wifiNetworksColumn
                    width: parent.width
                    height: visible ? Math.max(140 * root.uiScale, Math.min(wifiNetworksColumn.headerHeight + wifiNetworksList.contentHeight + wifiNetworksColumn.inputHeight + 24, 340 * root.uiScale)) : 0
                    visible: false
                    clip: true
                    color: root.withAlpha(root.getColor("bg", "#1a120e"), 0.95)
                    radius: root.quickMenuInnerRadius * root.uiScale
                    border.width: 1 * root.uiScale
                    border.color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.2)

                    readonly property int headerHeight: 28 * root.uiScale
                    property int inputHeight: 0
                    property string selectedSsid: ""
                    property bool needsPassword: false

                    Behavior on height { NumberAnimation { duration: 150 } }

                    property var wifiModel: ListModel { id: wifiListModel }

                    function refresh() {
                        quickMenuWifiListProc.running = true
                    }

                    function connectWithPassword(ssid, password) {
                        root.isWifiConnecting = true
                        wifiConnectProc.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password]
                        wifiConnectProc.running = true
                        wifiNetworksColumn.needsPassword = false
                        wifiNetworksColumn.inputHeight = 0
                        wifiNetworksColumn.selectedSsid = ""
                        wifiPasswordInput.text = ""
                        wifiRetryTimer.restart()
                    }

                    Process {
                        id: quickMenuWifiListProc
                        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "auto"]
                        stdout: StdioCollector { id: wifiListOut; waitForEnd: true; onStreamFinished: {
                            var entries = []
                            var lines = wifiListOut.text.split("\n")
                            for (var i = 0; i < lines.length; i++) {
                                var line = lines[i].trim()
                                if (line === "" || line.indexOf("IN-USE") === 0) continue
                                var parts = line.split(":")
                                if (parts.length < 4) continue
                                entries.push({
                                    connected: parts[0].trim() === "*",
                                    ssid: parts[1].trim(),
                                    signal: parseInt(parts[2].trim()) || 0,
                                    security: parts[3].trim()
                                })
                            }
                            wifiNetworksColumn.wifiModel.clear()
                            for (var k = 0; k < entries.length; k++) {
                                wifiNetworksColumn.wifiModel.append(entries[k])
                            }
                        }}
                    }

                    Process {
                        id: wifiConnectProc
                    }

                    // header row
                    Item {
                        id: wifiHeader
                        width: parent.width - 16
                        height: wifiNetworksColumn.headerHeight
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            text: "WiFi"
                            font.family: root.fontFamily
                            font.pixelSize: 12 * root.uiScale
                            font.bold: true
                            color: root.getColor("fg", "#f0dfd8")
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: 24 * root.uiScale
                            height: 24 * root.uiScale
                            radius: root.quickMenuInnerRadius * root.uiScale
                            color: wifiRefreshMouse.containsMouse
                                ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.2)
                                : "transparent"
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "↻"
                                font.family: root.fontFamily
                                font.pixelSize: 14 * root.uiScale
                                color: root.getColor("muted", "#a08d85")
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: wifiRefreshMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: wifiNetworksColumn.refresh()
                            }
                        }
                    }

                    // divider
                    Rectangle {
                        width: parent.width - 16
                        height: 1
                        anchors.top: wifiHeader.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.15)
                    }

                    // network list
                    ListView {
                        id: wifiNetworksList
                        width: parent.width
                        anchors.top: wifiHeader.bottom
                        anchors.topMargin: 8
                        anchors.bottom: wifiPasswordSection.visible ? wifiPasswordSection.top : parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 8
                        clip: true
                        model: wifiNetworksColumn.wifiModel
                        spacing: 4

                        // empty state
                        Text {
                            anchors.centerIn: parent
                            text: quickMenuWifiListProc.running ? "Scanning networks..." : "No networks found"
                            font.family: root.fontFamily
                            font.pixelSize: 11 * root.uiScale
                            color: root.getColor("muted", "#a08d85")
                            visible: wifiNetworksList.count === 0
                        }

                        delegate: Rectangle {
                            width: wifiNetworksList.width
                            height: 28 * root.uiScale
                            radius: root.quickMenuInnerRadius * root.uiScale
                            color: model.connected ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.15)
                                 : netMouse.containsMouse ? root.withAlpha(root.getColor("fg", "#f0dfd8"), 0.08)
                                 : "transparent"

                            Row {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 6

                                Text {
                                    text: model.security !== "" ? "󰌾" : ""
                                    font.family: root.fontFamily
                                    font.pixelSize: 10 * root.uiScale
                                    color: root.getColor("muted", "#a08d85")
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: model.ssid
                                    font.family: root.fontFamily
                                    font.pixelSize: 11 * root.uiScale
                                    font.bold: model.connected
                                    color: model.connected ? root.getColor("accent", "#ffb691") : root.getColor("fg", "#f0dfd8")
                                    elide: Text.ElideRight
                                    width: parent.width - 40
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: model.connected ? "✓" : ""
                                    font.family: root.fontFamily
                                    font.pixelSize: 10 * root.uiScale
                                    color: root.getColor("muted", "#a08d85")
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: netMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!model.connected) {
                                        if (model.security !== "") {
                                            // needs password
                                            wifiNetworksColumn.selectedSsid = model.ssid
                                            wifiNetworksColumn.needsPassword = true
                                            wifiNetworksColumn.inputHeight = 50 * root.uiScale
                                            wifiPasswordInput.text = ""
                                            wifiPasswordInput.forceActiveFocus()
                                        } else {
                                            // open network, connect directly
                                            root.isWifiConnecting = true
                                            wifiConnectProc.command = ["nmcli", "device", "wifi", "connect", model.ssid]
                                            wifiConnectProc.running = true
                                            wifiRetryTimer.restart()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // password input section
                    Column {
                        id: wifiPasswordSection
                        width: parent.width - 16
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6
                        visible: wifiNetworksColumn.needsPassword

                        Text {
                            text: "Password for " + wifiNetworksColumn.selectedSsid
                            font.family: root.fontFamily
                            font.pixelSize: 10 * root.uiScale
                            color: root.getColor("muted", "#a08d85")
                        }

                        property bool showPassword: false

                        Rectangle {
                            width: parent.width
                            height: 32 * root.uiScale
                            radius: root.quickMenuInnerRadius * root.uiScale
                            color: root.withAlpha(root.getColor("fg", "#f0dfd8"), 0.08)
                            border.width: 1 * root.uiScale
                            border.color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.3)

                            TextInput {
                                id: wifiPasswordInput
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.right: wifiEyeButton.left
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                height: parent.height - 16
                                font.family: root.fontFamily
                                font.pixelSize: 12 * root.uiScale
                                color: root.getColor("fg", "#f0dfd8")
                                echoMode: wifiPasswordSection.showPassword ? TextInput.Normal : TextInput.Password
                                verticalAlignment: Text.AlignVCenter
                                clip: true
                                property string placeholderText: "Enter password..."
                                Text {
                                    text: wifiPasswordInput.placeholderText
                                    font: wifiPasswordInput.font
                                    color: root.getColor("muted", "#a08d85")
                                    visible: !wifiPasswordInput.text && !wifiPasswordInput.activeFocus
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                onAccepted: {
                                    if (text.length > 0) {
                                        wifiNetworksColumn.connectWithPassword(wifiNetworksColumn.selectedSsid, text)
                                    }
                                }
                            }

                            // show/hide password eye button
                            Rectangle {
                                id: wifiEyeButton
                                width: 24 * root.uiScale
                                height: parent.height
                                anchors.right: parent.right
                                color: wifiEyeMouse.containsMouse
                                    ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.2)
                                    : "transparent"

                                Text {
                                    text: wifiPasswordSection.showPassword ? "󰈈" : "󰈉"
                                    font.family: root.fontFamily
                                    font.pixelSize: 14 * root.uiScale
                                    color: root.getColor("muted", "#a08d85")
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: wifiEyeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: wifiPasswordSection.showPassword = !wifiPasswordSection.showPassword
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 8

                            Rectangle {
                                width: (parent.width - 8) / 2
                                height: 28 * root.uiScale
                                radius: root.quickMenuInnerRadius * root.uiScale
                                color: wifiCancelMouse.containsMouse
                                    ? root.withAlpha(root.getColor("muted", "#a08d85"), 0.3)
                                    : root.withAlpha(root.getColor("muted", "#a08d85"), 0.15)

                                Text {
                                    text: "Cancel"
                                    font.family: root.fontFamily
                                    font.pixelSize: 11 * root.uiScale
                                    color: root.getColor("fg", "#f0dfd8")
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: wifiCancelMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        wifiNetworksColumn.needsPassword = false
                                        wifiNetworksColumn.inputHeight = 0
                                        wifiNetworksColumn.selectedSsid = ""
                                        wifiPasswordInput.text = ""
                                    }
                                }
                            }

                            Rectangle {
                                width: (parent.width - 8) / 2
                                height: 28 * root.uiScale
                                radius: root.quickMenuInnerRadius * root.uiScale
                                color: wifiConnectMouse.containsMouse
                                    ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.4)
                                    : root.withAlpha(root.getColor("accent", "#ffb691"), 0.2)

                                Text {
                                    text: "Connect"
                                    font.family: root.fontFamily
                                    font.pixelSize: 11 * root.uiScale
                                    font.bold: true
                                    color: root.getColor("accent", "#ffb691")
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: wifiConnectMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (wifiPasswordInput.text.length > 0) {
                                            wifiNetworksColumn.connectWithPassword(wifiNetworksColumn.selectedSsid, wifiPasswordInput.text)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Timer {
                        id: wifiRetryTimer
                        interval: 2000
                        onTriggered: {
                            root.pollWifi()
                            wifiNetworksColumn.refresh()
                        }
                    }
                }

                Row {
                    spacing: 10 * root.uiScale
                    width: parent.width
                    anchors.horizontalCenter: parent.horizontalCenter

                    PillButton {
                        iconText: root.isNightLightEnabled ? "󰛨" : "󰛩"
                        labelText: "Night Light"
                        isChecked: root.isNightLightEnabled
                        pillRadius: root.quickMenuInnerRadius * root.uiScale
                        iconUsesAccent: true
                        onClicked: root.toggleNightLight()
                    }

                    PillButton {
                        iconText: "󰒲"
                        labelText: "Caffeine"
                        isChecked: root.isCaffeineEnabled
                        pillRadius: root.quickMenuInnerRadius * root.uiScale
                        iconUsesAccent: true
                        onClicked: root.toggleCaffeine()
                    }

                    BatteryPill {
                        batteryLevel: root.batteryLevel
                        batteryStatus: root.batteryStatus
                        pillRadius: root.quickMenuInnerRadius * root.uiScale
                    }
                }

                SliderRow {
                    iconText: root.isVolumeMuted ? "" : ""
                    iconDimmed: root.isVolumeMuted
                    value: root.isVolumeMuted || root.volume < 0 ? 0 : root.volume
                    valueText: root.isVolumeMuted ? "Muted" : (root.volume < 0 ? "--" : root.volume + "%")
                    trackRadius: root.quickMenuInnerRadius * root.uiScale
                    onValuePreviewed: (newValue) => {
                        root.volume = newValue
                        root.isVolumeDragging = true
                    }
                    onValueCommitted: (newValue) => {
                        root.isVolumeDragging = false
                        root.setVolume(newValue)
                    }
                }

                SliderRow {
                    iconText: "󰃠"
                    value: root.brightnessLevel
                    showHandle: false
                    trackRadius: root.quickMenuInnerRadius * root.uiScale
                    onValuePreviewed: (newValue) => root.setBrightness(newValue)
                }

                Divider {
                    visible: root.mediaStatus !== "None"
                }

                MediaPlayerRow {
                    visible: root.mediaStatus !== "None"
                    mediaStatusText: root.mediaStatus
                    mediaTitleText: root.mediaTitle || root.mediaName || "Unknown"
                    mediaArtistText: root.mediaArtist || "Unknown Artist"
                    artUrl: root.mediaArtUrl || ""
                    mediaRadius: root.quickMenuInnerRadius * root.uiScale
                    onPlayPauseRequested: root.toggleMediaPlay()
                    onNextRequested: {
                        mediaNextProc.command = [root.swayScriptsDir + "/media-control", "Next"]
                        mediaNextProc.startDetached()
                        root.mediaResync.restart()
                    }
                }
            }

            PowerPage {
                id: powerPageColumn
                visible: root.isPowerPageOpen
                itemRadius: root.quickMenuInnerRadius * root.uiScale
            }

            NotificationPage {
                id: notifPageColumn
                visible: root.isNotificationPageOpen
                itemRadius: root.quickMenuInnerRadius * root.uiScale
            }

            ClipboardPage {
                id: clipPageColumn
                visible: root.isClipboardPageOpen
                itemRadius: root.quickMenuInnerRadius * root.uiScale
            }

            SettingsPage {
                id: settingsPageColumn
                visible: root.isSettingsPageOpen
                width: parent.width
                height: 200 * root.uiScale
            }
        }
    }
}
