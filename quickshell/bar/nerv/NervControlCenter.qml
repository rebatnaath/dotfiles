import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Shapes

// nerv control center -- port of the "nerv@hq : control-center" mockup,
// adapted to the rice's shared state: the toggle grid drives the same
// wifi/bluetooth/night-light/dnd functions the generic quick menu uses,
// sliders reuse the volume/brightness backends, and the status log polls
// real system values. NERV is a fixed theme, so its red/black identity
// palette is hardcoded here like in NervBar.
PanelWindow {
    id: ccWindow

    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    visible: root.isQuickMenuOpen && root.activeBar === "nerv"
    anchors { top: true; left: true; right: true; bottom: true }

    // ---- fixed NERV palette (mockup :root, red mapped to the bar's #9D0A12)
    readonly property color cRed: "#9D0A12"
    readonly property color cRedDim: "#6E0D13"
    readonly property color cOrange: "#ff9a1f"
    readonly property color cCyan: "#5fc4dc"
    readonly property color cGreen: "#63d98b"
    readonly property color cText: "#c9c9c2"
    readonly property color cDim: "#7d7d76"
    readonly property color cWhite: "#f2f2ec"
    readonly property color cBg: "#0a0a0a"
    readonly property color cPanel: "#0d0d0d"

    // ---- system info (uptime / ram), polled while the menu is open
    property string uptimeText: "--"
    property string ramText: "--"

    Process {
        id: sysInfoProc
        command: ["bash", "-c",
            "awk '{d=int($1/86400); h=int($1%86400/3600); m=int($1%3600/60); printf \"%dd %dh %dmin\\n\", d, h, m}' /proc/uptime; free --si -h | awk '/Mem:/{print $3\" / \"$2}'"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var lines = text.trim().split("\n")
                ccWindow.uptimeText = lines[0] || "--"
                ccWindow.ramText = lines[1] || "--"
            }
        }
    }

    Timer {
        interval: 5000
        running: ccWindow.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!sysInfoProc.running) sysInfoProc.exec(sysInfoProc.command)
    }

    Process { id: actionProc }

    function run(cmd) {
        actionProc.command = cmd
        actionProc.startDetached()
    }

    function powerAction(action) {
        if (action === "lock") run(["swaylock"])
        else if (action === "suspend") run(["systemctl", "suspend"])
        else if (action === "logout") run(["swaymsg", "exit"])
        else if (action === "reboot") run(["systemctl", "reboot"])
        else if (action === "shutdown") run(["systemctl", "poweroff"])
        root.isQuickMenuOpen = false
    }

    // Click outside the frame closes.
    MouseArea {
        anchors.fill: parent
        onClicked: root.isQuickMenuOpen = false
    }

    // ---- outer frame (.frame): 3px red border + inner dim ring (::before)
    Rectangle {
        id: frame
        // floating, centred on the screen
        anchors.centerIn: parent
        width: 660 * root.uiScale
        height: frameColumn.implicitHeight + 40 * root.uiScale
        radius: 6 * root.uiScale
        color: ccWindow.cBg
        border.width: 3 * root.uiScale
        border.color: ccWindow.cRed

        // faint red wash approximating the mockup's radial-gradient corner
        // glow (Shapes gradients can't render standalone, so keep it simple)
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Qt.rgba(0.616, 0.039, 0.071, 0.04)
        }

        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => mouse.accepted = true
        }

        Column {
            id: frameColumn
            anchors {
                left: parent.left; right: parent.right; top: parent.top
                margins: 20 * root.uiScale
            }
            spacing: 16 * root.uiScale

            // ---- topbar: label left, clock right
            Item {
                width: parent.width
                height: Math.max(topLabel.implicitHeight, topClock.implicitHeight)

                Text {
                    id: topLabel
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "nerv@hq : control-center"
                    font.family: root.fontFamily
                    font.pixelSize: 13 * root.uiScale
                    font.letterSpacing: 0.5 * root.uiScale
                    color: ccWindow.cGreen
                }

                Text {
                    id: topClock
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.dateTimeText.toUpperCase()
                    font.family: root.fontFamily
                    font.pixelSize: 13 * root.uiScale
                    font.bold: true
                    font.letterSpacing: 1 * root.uiScale
                    color: ccWindow.cOrange
                }
            }

            Rectangle { width: parent.width; height: 1 * root.uiScale; color: ccWindow.cRedDim }

            // ---- main grid: left column wider than right (1.15fr / 1fr)
            Row {
                width: parent.width
                spacing: 16 * root.uiScale

                // ==================== LEFT COLUMN ====================
                Column {
                    width: parent.width * 0.53 - 8 * root.uiScale
                    spacing: 16 * root.uiScale

                    // ---- quick-toggles box
                    Rectangle {
                        width: parent.width
                        height: togglesInner.implicitHeight + 28 * root.uiScale
                        radius: 4 * root.uiScale
                        color: ccWindow.cPanel
                        border.width: 1 * root.uiScale
                        border.color: ccWindow.cRed

                        Column {
                            id: togglesInner
                            anchors {
                                left: parent.left; right: parent.right; top: parent.top
                                margins: 14 * root.uiScale
                            }
                            spacing: 12 * root.uiScale

                            Text {
                                text: "$ quick-toggles"
                                font.family: root.fontFamily
                                font.pixelSize: 12 * root.uiScale
                                font.letterSpacing: 0.5 * root.uiScale
                                color: ccWindow.cGreen
                            }

                            Grid {
                                width: parent.width
                                columns: 2
                                spacing: 10 * root.uiScale

                                Repeater {
                                    model: [
                                        { name: "wifi", checkedB: root.wifiName !== "", busy: root.isWifiConnecting,
                                          fn: "toggleWifi",
                                          subFn: function() {
                                              if (root.isWifiConnecting) return "connecting..."
                                              return root.wifiName === "" ? "offline" : root.wifiName } },
                                        { name: "bluetooth", checkedB: root.bluetoothEnabled, busy: root.isBluetoothConnecting,
                                          fn: "toggleBluetooth",
                                          subFn: function() {
                                              if (root.isBluetoothConnecting) return "syncing..."
                                              return root.bluetoothEnabled ? "magi-link active" : "off" } },
                                        { name: "night-light", checkedB: root.isNightLightEnabled, busy: false,
                                          fn: "toggleNightLight",
                                          subFn: function() {
                                              return root.isNightLightEnabled ? "warmth active" : "off" } },
                                        { name: "dnd", checkedB: root.isDndEnabled, busy: false,
                                          fn: "toggleDnd",
                                          subFn: function() {
                                              return root.isDndEnabled ? "ex_mode on" : "ex_mode off" } }
                                    ]

                                    delegate: Rectangle {
                                        id: toggleCard
                                        required property var modelData
                                        readonly property bool isOn: modelData.checkedB || modelData.busy
                                        width: (parent.width - parent.spacing) / 2
                                        height: 46 * root.uiScale
                                        radius: 4 * root.uiScale
                                        color: isOn ? Qt.rgba(0.373, 0.769, 0.863, 0.06)
                                            : (toggleMouse.containsMouse ? Qt.rgba(0.616, 0.039, 0.071, 0.08) : "transparent")
                                        border.width: 1 * root.uiScale
                                        border.color: isOn ? ccWindow.cCyan
                                            : (toggleMouse.containsMouse ? ccWindow.cRed : ccWindow.cRedDim)
                                        Behavior on border.color { ColorAnimation { duration: 150 } }
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Column {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10 * root.uiScale
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 2 * root.uiScale

                                            Text {
                                                text: toggleCard.modelData.busy ? "syncing" : toggleCard.modelData.name
                                                font.family: root.fontFamily
                                                font.pixelSize: 12 * root.uiScale
                                                color: toggleCard.isOn ? ccWindow.cCyan : ccWindow.cWhite
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }

                                            Text {
                                                text: toggleCard.modelData.subFn()
                                                elide: Text.ElideRight
                                                width: toggleCard.width - 66 * root.uiScale
                                                font.family: root.fontFamily
                                                font.pixelSize: 9.5 * root.uiScale
                                                color: ccWindow.cDim
                                            }
                                        }

                                        // switch pill (.switch)
                                        Rectangle {
                                            anchors.right: parent.right
                                            anchors.rightMargin: 10 * root.uiScale
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 30 * root.uiScale
                                            height: 15 * root.uiScale
                                            radius: 7.5 * root.uiScale
                                            color: "transparent"
                                            border.width: 1 * root.uiScale
                                            border.color: toggleCard.isOn ? ccWindow.cCyan : ccWindow.cRedDim
                                            Behavior on border.color { ColorAnimation { duration: 150 } }

                                            Rectangle {
                                                x: toggleCard.isOn
                                                    ? parent.width - width - 2 * root.uiScale : 1 * root.uiScale
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 11 * root.uiScale
                                                height: 11 * root.uiScale
                                                radius: width / 2
                                                color: toggleCard.isOn ? ccWindow.cCyan : ccWindow.cDim
                                                Behavior on x { NumberAnimation { duration: 150 } }
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }
                                        }

                                        MouseArea {
                                            id: toggleMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root[toggleCard.modelData.fn]()
                                        }
                                    }
                                }
                            }

                            // ---- sliders (.sliders): volume orange, brightness cyan
                            Column {
                                width: parent.width
                                spacing: 14 * root.uiScale

                                Repeater {
                                    model: [
                                        { name: "volume", kind: "volume", cyanFill: false },
                                        { name: "brightness", kind: "brightness", cyanFill: true }
                                    ]

                                    delegate: Item {
                                        id: sliderRow
                                        required property var modelData
                                        width: parent.width
                                        height: sName.implicitHeight + 14 * root.uiScale

                                        readonly property bool isVolume: modelData.kind === "volume"
                                        readonly property real current: isVolume
                                            ? (root.isVolumeMuted || root.volume < 0 ? 0 : root.volume)
                                            : root.brightnessLevel
                                        readonly property color fillColor: modelData.cyanFill
                                            ? ccWindow.cCyan : ccWindow.cOrange

                                        Text {
                                            id: sName
                                            anchors.left: parent.left
                                            text: sliderRow.modelData.name
                                            font.family: root.fontFamily
                                            font.pixelSize: 11.5 * root.uiScale
                                            color: ccWindow.cText
                                        }

                                        Text {
                                            anchors.right: parent.right
                                            text: sliderRow.isVolume
                                                ? (root.isVolumeMuted ? "muted" : (root.volume < 0 ? "--" : Math.round(root.volume) + "%"))
                                                : (root.brightnessLevel < 0 ? "--" : root.brightnessLevel + "%")
                                            font.family: root.fontFamily
                                            font.pixelSize: 11.5 * root.uiScale
                                            color: ccWindow.cOrange
                                        }

                                        Rectangle {
                                            id: sTrack
                                            anchors.top: sName.bottom
                                            anchors.topMargin: 5 * root.uiScale
                                            width: parent.width
                                            height: 8 * root.uiScale
                                            radius: 4 * root.uiScale
                                            color: "#1c1c1a"
                                            border.width: 1 * root.uiScale
                                            border.color: ccWindow.cRedDim

                                            Rectangle {
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left
                                                anchors.leftMargin: 1 * root.uiScale
                                                height: parent.height - 2 * root.uiScale
                                                width: Math.max(0, Math.min(100, sliderRow.current)) / 100
                                                    * (parent.width - 2 * root.uiScale)
                                                radius: 3 * root.uiScale
                                                color: sTrackMouse.containsMouse
                                                    ? Qt.lighter(sliderRow.fillColor, 1.15) : sliderRow.fillColor
                                                Behavior on color { ColorAnimation { duration: 120 } }
                                            }

                                            MouseArea {
                                                id: sTrackMouse
                                                anchors { fill: parent; topMargin: -6; bottomMargin: -6 }
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor

                                                function valueAt(mouseX) {
                                                    return Math.max(0, Math.min(100,
                                                        (mouseX - 1 * root.uiScale) / (width - 2 * root.uiScale) * 100))
                                                }
                                                onPressed: (mouse) => apply(valueAt(mouse.x), true)
                                                onPositionChanged: (mouse) => { if (pressed) apply(valueAt(mouse.x), true) }
                                                onReleased: (mouse) => apply(valueAt(mouse.x), false)

                                                function apply(v, preview) {
                                                    if (sliderRow.isVolume) {
                                                        root.isVolumeDragging = preview
                                                        root.volume = v
                                                        if (!preview) { root.isVolumeDragging = false; root.setVolume(v) }
                                                    } else {
                                                        root.setBrightness(Math.round(v))
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ---- status log box ($ cat /sys/status.log)
                    Rectangle {
                        width: parent.width
                        height: statusInner.implicitHeight + 28 * root.uiScale
                        radius: 4 * root.uiScale
                        color: ccWindow.cPanel
                        border.width: 1 * root.uiScale
                        border.color: ccWindow.cRed

                        Column {
                            id: statusInner
                            anchors {
                                left: parent.left; right: parent.right; top: parent.top
                                margins: 14 * root.uiScale
                            }
                            spacing: 8 * root.uiScale

                            Text {
                                text: "$ cat /sys/status.log"
                                font.family: root.fontFamily
                                font.pixelSize: 12 * root.uiScale
                                font.letterSpacing: 0.5 * root.uiScale
                                color: ccWindow.cGreen
                            }

                            Repeater {
                                model: [
                                    { k: "battery",
                                      v: (root.batteryLevel >= 0 ? root.batteryLevel : "--") + "%"
                                         + (root.batteryStatus === "Charging" ? " · charging" : ""),
                                      color: ccWindow.cOrange },
                                    { k: "uptime", v: ccWindow.uptimeText, color: ccWindow.cWhite },
                                    { k: "ram", v: ccWindow.ramText, color: ccWindow.cWhite },
                                    { k: "net", v: root.wifiName === "" ? "offline" : root.wifiName, color: ccWindow.cCyan }
                                ]

                                delegate: Item {
                                    id: statusLine
                                    required property var modelData
                                    width: parent.width
                                    height: Math.max(kText.implicitHeight, vText.implicitHeight) + 6 * root.uiScale

                                    Text {
                                        id: kText
                                        anchors.left: parent.left
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 6 * root.uiScale
                                        text: statusLine.modelData.k
                                        font.family: root.fontFamily
                                        font.pixelSize: 11.5 * root.uiScale
                                        color: ccWindow.cDim
                                    }

                                    Text {
                                        id: vText
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 6 * root.uiScale
                                        text: statusLine.modelData.v
                                        font.family: root.fontFamily
                                        font.pixelSize: 11.5 * root.uiScale
                                        color: statusLine.modelData.color
                                    }

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: 1
                                        color: ccWindow.cRedDim
                                        opacity: 0.55
                                    }
                                }
                            }
                        }
                    }
                }

                // ==================== RIGHT COLUMN ====================
                Column {
                    width: parent.width * 0.47 - 8 * root.uiScale
                    spacing: 16 * root.uiScale

                    // ---- MAGI status box
                    Rectangle {
                        width: parent.width
                        height: magiInner.implicitHeight + 28 * root.uiScale
                        radius: 4 * root.uiScale
                        color: ccWindow.cPanel
                        border.width: 1 * root.uiScale
                        border.color: ccWindow.cRed

                        Column {
                            id: magiInner
                            anchors {
                                left: parent.left; right: parent.right; top: parent.top
                                margins: 14 * root.uiScale
                            }
                            spacing: 10 * root.uiScale

                            // 制御 CONTROL header, centered like the mockup box
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "制御 CONTROL"
                                font.family: root.fontFamily
                                font.pixelSize: 17 * root.uiScale
                                font.bold: true
                                color: ccWindow.cOrange
                            }

                            // MAGI hexes: DISPLAY / AUDIO / NETWORK, driven by
                            // live state (filled cyan/green when ok, orange
                            // outline when degraded)
                            Repeater {
                                model: [
                                    { name: "DISPLAY",
                                      val: root.brightnessLevel < 0 ? "no signal" : "brightness " + root.brightnessLevel + "%",
                                      mode: root.brightnessLevel < 0 ? "outline" : "cyan" },
                                    { name: "AUDIO",
                                      val: root.isVolumeMuted ? "muted" : (root.volume < 0 ? "--" : Math.round(root.volume) + "%"),
                                      mode: root.isVolumeMuted ? "outline" : "cyan" },
                                    { name: "NETWORK",
                                      val: root.wifiName === "" ? "unlinked" : "linked",
                                      mode: root.wifiName === "" ? "outline" : "green" }
                                ]

                                delegate: Rectangle {
                                    id: hexChip
                                    required property var modelData
                                    width: parent.width
                                    height: 48 * root.uiScale
                                    radius: 3 * root.uiScale
                                    border.width: hexChip.modelData.mode === "outline" ? 2 * root.uiScale : 0
                                    border.color: ccWindow.cOrange
                                    color: hexChip.modelData.mode === "cyan" ? ccWindow.cCyan
                                        : hexChip.modelData.mode === "green" ? ccWindow.cGreen : "transparent"

                                    readonly property color fgColor: hexChip.modelData.mode === "cyan" ? "#04303c"
                                        : hexChip.modelData.mode === "green" ? "#0a3a1c" : ccWindow.cOrange

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 2 * root.uiScale

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: hexChip.modelData.name
                                            font.family: root.fontFamily
                                            font.pixelSize: 11 * root.uiScale
                                            font.bold: true
                                            font.letterSpacing: 0.5 * root.uiScale
                                            color: hexChip.fgColor
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: hexChip.modelData.val
                                            font.family: root.fontFamily
                                            font.pixelSize: 10 * root.uiScale
                                            opacity: 0.85
                                            color: hexChip.fgColor
                                        }
                                    }
                                }
                            }

                            Rectangle { width: parent.width; height: 1; color: ccWindow.cRedDim; opacity: 0.55 }

                            // session rows under the hexes
                            Repeater {
                                model: [
                                    { k: "access code", v: "\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022", color: ccWindow.cWhite },
                                    { k: "session", v: "nerv@hq :: sway", color: ccWindow.cOrange }
                                ]

                                delegate: Item {
                                    required property var modelData
                                    width: parent.width
                                    height: Math.max(magiK.implicitHeight, magiV.implicitHeight)

                                    Text {
                                        id: magiK
                                        anchors.left: parent.left
                                        text: modelData.k
                                        font.family: root.fontFamily
                                        font.pixelSize: 11.5 * root.uiScale
                                        color: ccWindow.cDim
                                    }

                                    Text {
                                        id: magiV
                                        anchors.right: parent.right
                                        text: modelData.v
                                        font.family: root.fontFamily
                                        font.pixelSize: 11.5 * root.uiScale
                                        color: modelData.color
                                    }
                                }
                            }
                        }
                    }

                    // ---- quick-actions box
                    Rectangle {
                        width: parent.width
                        height: actionsInner.implicitHeight + 28 * root.uiScale
                        radius: 4 * root.uiScale
                        color: ccWindow.cPanel
                        border.width: 1 * root.uiScale
                        border.color: ccWindow.cRed

                        Column {
                            id: actionsInner
                            anchors {
                                left: parent.left; right: parent.right; top: parent.top
                                margins: 14 * root.uiScale
                            }
                            spacing: 8 * root.uiScale

                            Text {
                                text: "$ quick-actions"
                                font.family: root.fontFamily
                                font.pixelSize: 12 * root.uiScale
                                font.letterSpacing: 0.5 * root.uiScale
                                color: ccWindow.cGreen
                            }

                            Repeater {
                                model: [
                                    { k: "screenshot", v: "super+shift+s", script: "",
                                      cmd: 'mkdir -p "$HOME/Pictures/Screenshots/sway" && grim -g "$(slurp)" - | tee "$HOME/Pictures/Screenshots/sway/screenshot-$(date +%Y-%m-%d_%H%M%S).png" | wl-copy' },
                                    { k: "screen record", v: "super+ctrl+r", script: "rec-toggle.sh", cmd: "" },
                                    { k: "wallpaper", v: "wall-pick", script: "wall-pick", cmd: "" },
                                    { k: "color scheme", v: "matugen · dark", script: "theme-switch", cmd: "" }
                                ]

                                delegate: Item {
                                    id: actionLine
                                    required property var modelData
                                    width: parent.width
                                    height: Math.max(aKey.implicitHeight, aVal.implicitHeight) + 8 * root.uiScale

                                    Text {
                                        id: aKey
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: actionLine.modelData.k
                                        font.family: root.fontFamily
                                        font.pixelSize: 11.5 * root.uiScale
                                        color: ccWindow.cWhite
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    Text {
                                        id: aVal
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: actionLine.modelData.v
                                        font.family: root.fontFamily
                                        font.pixelSize: 11.5 * root.uiScale
                                        color: ccWindow.cWhite
                                    }

                                    MouseArea {
                                        id: actionMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (actionLine.modelData.script !== "")
                                                ccWindow.run([root.swayScriptsDir + "/" + actionLine.modelData.script])
                                            else
                                                ccWindow.run(["bash", "-c", actionLine.modelData.cmd])
                                            if (actionLine.modelData.k !== "screen record")
                                                root.isQuickMenuOpen = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---- power navbar (.navbar): pentagon items + zone tag
            Rectangle {
                width: parent.width
                height: 46 * root.uiScale
                radius: 4 * root.uiScale
                color: ccWindow.cPanel
                border.width: 1 * root.uiScale
                border.color: ccWindow.cRed
                clip: true

                Row {
                    id: navRow
                    anchors.fill: parent

                    Repeater {
                        model: [
                            { name: "lock", danger: false },
                            { name: "suspend", danger: false },
                            { name: "logout", danger: false },
                            { name: "reboot", danger: false },
                            { name: "shutdown", danger: true }
                        ]

                        delegate: Rectangle {
                            id: navItem
                            required property var modelData
                            width: (navRow.width - zoneTag.width) / 5
                            height: navRow.height
                            color: navMa.containsMouse ? Qt.rgba(0.616, 0.039, 0.071, 0.08) : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 1 * root.uiScale
                                color: ccWindow.cRedDim
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 8 * root.uiScale

                                // pentagon icon (css clip-path polygon)
                                Shape {
                                    width: 10 * root.uiScale
                                    height: 10 * root.uiScale
                                    anchors.verticalCenter: parent.verticalCenter

                                    ShapePath {
                                        fillColor: navItem.modelData.danger ? ccWindow.cOrange : ccWindow.cRed
                                        strokeColor: navItem.modelData.danger ? ccWindow.cOrange : ccWindow.cRed
                                        strokeWidth: 1

                                        PathSvg {
                                            path: {
                                                var s = 10 * root.uiScale / 100
                                                return "M" + 50*s + " 0 L" + 100*s + " " + 38*s +
                                                    " L" + 82*s + " " + 100*s + " L" + 18*s + " " + 100*s +
                                                    " L0 " + 38*s + " Z"
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: navItem.modelData.name
                                    font.family: root.fontFamily
                                    font.pixelSize: 12 * root.uiScale
                                    font.letterSpacing: 1 * root.uiScale
                                    color: navMa.containsMouse ? ccWindow.cWhite : ccWindow.cText
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                            }

                            MouseArea {
                                id: navMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ccWindow.powerAction(navItem.modelData.name)
                            }
                        }
                    }

                    // 電源 POWER ZONE tag on the right edge
                    Rectangle {
                        id: zoneTag
                        width: 92 * root.uiScale
                        height: parent.height
                        color: "transparent"

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 1 * root.uiScale
                            color: ccWindow.cRedDim
                        }

                        Column {
                            anchors.right: parent.right
                            anchors.rightMargin: 14 * root.uiScale
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                anchors.right: parent.right
                                text: "電源"
                                font.family: root.fontFamily
                                font.pixelSize: 12 * root.uiScale
                                font.bold: true
                                color: ccWindow.cOrange
                            }

                            Text {
                                anchors.right: parent.right
                                text: "POWER ZONE"
                                font.family: root.fontFamily
                                font.pixelSize: 9 * root.uiScale
                                color: ccWindow.cDim
                            }
                        }
                    }
                }
            }
        }
    }
}
