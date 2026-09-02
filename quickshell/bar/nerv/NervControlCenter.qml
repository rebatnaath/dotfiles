import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Shapes

// nerv control center -- balanced: preserves nerv aesthetic, less busy
PanelWindow {
    id: ccWindow

    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    visible: root.isQuickMenuOpen && root.activeBar === "nerv"
    anchors { top: true; left: true; right: true; bottom: true }

    // muted NERV palette
    readonly property color cRed: "#9D0A12"
    readonly property color cRedDim: "#3a1015"
    readonly property color cText: "#b0b0a8"
    readonly property color cDim: "#606058"
    readonly property color cWhite: "#e8e8e0"
    readonly property color cBg: "#0a0a0a"
    readonly property color cPanel: "#0d0d0d"

    // system info
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

    MouseArea {
        anchors.fill: parent
        onClicked: root.isQuickMenuOpen = false
    }

    // frame
    Rectangle {
        id: frame
        anchors.centerIn: parent
        width: 580 * root.uiScale
        height: frameColumn.implicitHeight + 32 * root.uiScale
        radius: 4 * root.uiScale
        color: ccWindow.cBg
        border.width: 1
        border.color: ccWindow.cRedDim

        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => mouse.accepted = true
        }

        Column {
            id: frameColumn
            anchors {
                left: parent.left; right: parent.right; top: parent.top
                margins: 16 * root.uiScale
            }
            spacing: 12 * root.uiScale

            // main grid
            Row {
                width: parent.width
                spacing: 12 * root.uiScale

                // left column
                Column {
                    width: parent.width * 0.55 - 6 * root.uiScale
                    spacing: 12 * root.uiScale

                    // toggles
                    Rectangle {
                        width: parent.width
                        height: togglesGrid.implicitHeight + 20 * root.uiScale
                        radius: 3 * root.uiScale
                        color: ccWindow.cPanel
                        border.width: 1
                        border.color: ccWindow.cRedDim

                        Column {
                            id: togglesGrid
                            anchors {
                                left: parent.left; right: parent.right; top: parent.top
                                margins: 12 * root.uiScale
                            }
                            spacing: 10 * root.uiScale

                            Text {
                                text: "$ toggles"
                                font.family: root.fontFamily
                                font.pixelSize: 10 * root.uiScale
                                color: ccWindow.cDim
                            }

                            Grid {
                                width: parent.width
                                columns: 2
                                spacing: 8 * root.uiScale

                                Repeater {
                                    model: [
                                        { name: "wifi", on: root.wifiName !== "", sub: root.wifiName || "off", fn: "toggleWifi" },
                                        { name: "bt", on: root.bluetoothEnabled, sub: root.bluetoothEnabled ? "on" : "off", fn: "toggleBluetooth" },
                                        { name: "nl", on: root.isNightLightEnabled, sub: root.isNightLightEnabled ? "on" : "off", fn: "toggleNightLight" },
                                        { name: "dnd", on: root.isDndEnabled, sub: root.isDndEnabled ? "on" : "off", fn: "toggleDnd" }
                                    ]

                                    delegate: Rectangle {
                                        required property var modelData
                                        width: (parent.width - 8 * root.uiScale) / 2
                                        height: 36 * root.uiScale
                                        radius: 2 * root.uiScale
                                        color: modelData.on ? Qt.rgba(0.616, 0.039, 0.071, 0.12) : "transparent"
                                        border.width: 1
                                        border.color: modelData.on ? ccWindow.cRed : ccWindow.cRedDim

                                        Column {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 8 * root.uiScale
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 1

                                            Text {
                                                text: modelData.name
                                                font.family: root.fontFamily
                                                font.pixelSize: 10 * root.uiScale
                                                color: modelData.on ? ccWindow.cWhite : ccWindow.cDim
                                            }

                                            Text {
                                                text: modelData.sub
                                                font.family: root.fontFamily
                                                font.pixelSize: 8 * root.uiScale
                                                color: ccWindow.cDim
                                            }
                                        }

                                        // indicator dot
                                        Rectangle {
                                            anchors.right: parent.right
                                            anchors.rightMargin: 8 * root.uiScale
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 6 * root.uiScale
                                            height: 6 * root.uiScale
                                            radius: 3 * root.uiScale
                                            color: modelData.on ? ccWindow.cRed : ccWindow.cRedDim
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root[modelData.fn]()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // sliders
                    Rectangle {
                        width: parent.width
                        height: slidersCol.implicitHeight + 20 * root.uiScale
                        radius: 3 * root.uiScale
                        color: ccWindow.cPanel
                        border.width: 1
                        border.color: ccWindow.cRedDim

                        Column {
                            id: slidersCol
                            anchors {
                                left: parent.left; right: parent.right; top: parent.top
                                margins: 12 * root.uiScale
                            }
                            spacing: 10 * root.uiScale

                            Text {
                                text: "$ levels"
                                font.family: root.fontFamily
                                font.pixelSize: 10 * root.uiScale
                                color: ccWindow.cDim
                            }

                            Repeater {
                                model: [
                                    { name: "vol", kind: "volume", val: root.isVolumeMuted ? "muted" : (root.volume >= 0 ? root.volume + "%" : "--"), level: root.isVolumeMuted ? 0 : root.volume },
                                    { name: "lux", kind: "brightness", val: root.brightnessLevel >= 0 ? root.brightnessLevel + "%" : "--", level: root.brightnessLevel }
                                ]

                                delegate: Column {
                                    required property var modelData
                                    width: parent.width
                                    spacing: 3 * root.uiScale

                                    Row {
                                        width: parent.width

                                        Text {
                                            text: modelData.name
                                            font.family: root.fontFamily
                                            font.pixelSize: 10 * root.uiScale
                                            color: ccWindow.cDim
                                        }

                                        Item { width: parent.width - modelData.name.length * 6 - sliderVal.implicitWidth - 16 * root.uiScale; height: 1 }

                                        Text {
                                            id: sliderVal
                                            text: modelData.val
                                            font.family: root.fontFamily
                                            font.pixelSize: 10 * root.uiScale
                                            color: ccWindow.cText
                                        }
                                    }

                                    Rectangle {
                                        id: sliderTrack
                                        width: parent.width
                                        height: 4 * root.uiScale
                                        radius: 2 * root.uiScale
                                        color: "#151515"

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            height: parent.height
                                            width: Math.max(0, Math.min(100, modelData.level)) / 100 * parent.width
                                            radius: 2 * root.uiScale
                                            color: ccWindow.cRed
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor

                                            function valueAt(mouseX) {
                                                return Math.max(0, Math.min(100,
                                                    mouseX / sliderTrack.width * 100))
                                            }

                                            onPressed: (mouse) => apply(valueAt(mouse.x), true)
                                            onPositionChanged: (mouse) => { if (pressed) apply(valueAt(mouse.x), true) }
                                            onReleased: (mouse) => apply(valueAt(mouse.x), false)

                                            function apply(v, preview) {
                                                if (modelData.kind === "volume") {
                                                    root.isVolumeDragging = preview
                                                    root.volume = v
                                                    if (!preview) {
                                                        root.isVolumeDragging = false
                                                        root.setVolume(v)
                                                    }
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

                // right column
                Column {
                    width: parent.width * 0.45 - 6 * root.uiScale
                    spacing: 12 * root.uiScale

                    // MAGI status
                    Rectangle {
                        width: parent.width
                        height: magiInner.implicitHeight + 20 * root.uiScale
                        radius: 3 * root.uiScale
                        color: ccWindow.cPanel
                        border.width: 1
                        border.color: ccWindow.cRedDim

                        Column {
                            id: magiInner
                            anchors {
                                left: parent.left; right: parent.right; top: parent.top
                                margins: 12 * root.uiScale
                            }
                            spacing: 8 * root.uiScale

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "制御 CONTROL"
                                font.family: root.fontFamily
                                font.pixelSize: 13 * root.uiScale
                                font.bold: true
                                color: ccWindow.cText
                            }

                            Repeater {
                                model: [
                                    { name: "DISPLAY", val: root.brightnessLevel >= 0 ? root.brightnessLevel + "%" : "--", ok: root.brightnessLevel >= 0 },
                                    { name: "AUDIO", val: root.isVolumeMuted ? "muted" : (root.volume >= 0 ? root.volume + "%" : "--"), ok: !root.isVolumeMuted },
                                    { name: "NETWORK", val: root.wifiName || "unlinked", ok: root.wifiName !== "" }
                                ]

                                delegate: Row {
                                    required property var modelData
                                    width: parent.width
                                    spacing: 8 * root.uiScale

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 6 * root.uiScale
                                        height: 6 * root.uiScale
                                        radius: 3 * root.uiScale
                                        color: modelData.ok ? ccWindow.cRed : ccWindow.cRedDim
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1

                                        Text {
                                            text: modelData.name
                                            font.family: root.fontFamily
                                            font.pixelSize: 9 * root.uiScale
                                            color: ccWindow.cDim
                                        }

                                        Text {
                                            text: modelData.val
                                            font.family: root.fontFamily
                                            font.pixelSize: 10 * root.uiScale
                                            color: ccWindow.cText
                                        }
                                    }
                                }
                            }

                            Rectangle { width: parent.width; height: 1; color: ccWindow.cRedDim }

                            // session info
                            Row {
                                width: parent.width
                                spacing: 8 * root.uiScale

                                Column {
                                    width: parent.width * 0.5
                                    spacing: 2

                                    Text { text: "session"; font.family: root.fontFamily; font.pixelSize: 8 * root.uiScale; color: ccWindow.cDim }
                                    Text { text: "nerv@hq :: sway"; font.family: root.fontFamily; font.pixelSize: 9 * root.uiScale; color: ccWindow.cText }
                                }

                                Column {
                                    width: parent.width * 0.5
                                    spacing: 2

                                    Text { text: "access"; font.family: root.fontFamily; font.pixelSize: 8 * root.uiScale; color: ccWindow.cDim }
                                    Text { text: "••••••••••••"; font.family: root.fontFamily; font.pixelSize: 9 * root.uiScale; color: ccWindow.cText }
                                }
                            }
                        }
                    }

                    // status
                    Rectangle {
                        width: parent.width
                        height: statusInner.implicitHeight + 20 * root.uiScale
                        radius: 3 * root.uiScale
                        color: ccWindow.cPanel
                        border.width: 1
                        border.color: ccWindow.cRedDim

                        Column {
                            id: statusInner
                            anchors {
                                left: parent.left; right: parent.right; top: parent.top
                                margins: 12 * root.uiScale
                            }
                            spacing: 6 * root.uiScale

                            Text {
                                text: "$ cat /sys/status.log"
                                font.family: root.fontFamily
                                font.pixelSize: 10 * root.uiScale
                                color: ccWindow.cDim
                            }

                            Repeater {
                                model: [
                                    { k: "bat", v: (root.batteryLevel >= 0 ? root.batteryLevel + "%" : "--") + (root.batteryStatus === "Charging" ? " +" : "") },
                                    { k: "up", v: ccWindow.uptimeText },
                                    { k: "ram", v: ccWindow.ramText },
                                    { k: "net", v: root.wifiName || "offline" }
                                ]

                                delegate: Row {
                                    required property var modelData
                                    width: parent.width
                                    spacing: 8 * root.uiScale

                                    Text {
                                        text: modelData.k
                                        font.family: root.fontFamily
                                        font.pixelSize: 10 * root.uiScale
                                        color: ccWindow.cDim
                                        width: 24 * root.uiScale
                                    }

                                    Text {
                                        text: modelData.v
                                        font.family: root.fontFamily
                                        font.pixelSize: 10 * root.uiScale
                                        color: ccWindow.cText
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: ccWindow.cRedDim }

            // power bar
            Row {
                width: parent.width
                spacing: 0

                Repeater {
                    model: [
                        { name: "lock", icon: "l" },
                        { name: "suspend", icon: "s" },
                        { name: "logout", icon: "x" },
                        { name: "reboot", icon: "r" },
                        { name: "shutdown", icon: "p" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        width: (parent.width - 80 * root.uiScale) / 5
                        height: 32 * root.uiScale
                        color: powerMa.containsMouse ? Qt.rgba(0.616, 0.039, 0.071, 0.2) : "transparent"

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 1
                            color: ccWindow.cRedDim
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6 * root.uiScale

                            Shape {
                                width: 8 * root.uiScale
                                height: 8 * root.uiScale
                                anchors.verticalCenter: parent.verticalCenter

                                ShapePath {
                                    fillColor: powerMa.containsMouse ? ccWindow.cRed : ccWindow.cRedDim
                                    strokeColor: "transparent"

                                    PathSvg {
                                        path: "M4 0 L8 3 L6.5 8 L1.5 8 L0 3 Z"
                                    }
                                }
                            }

                            Text {
                                text: modelData.name
                                font.family: root.fontFamily
                                font.pixelSize: 10 * root.uiScale
                                color: powerMa.containsMouse ? ccWindow.cWhite : ccWindow.cDim
                            }
                        }

                        MouseArea {
                            id: powerMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ccWindow.powerAction(modelData.name)
                        }
                    }
                }

                // zone tag
                Rectangle {
                    width: 80 * root.uiScale
                    height: parent.height
                    color: "transparent"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1
                        color: ccWindow.cRedDim
                    }

                    Column {
                        anchors.right: parent.right
                        anchors.rightMargin: 10 * root.uiScale
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            anchors.right: parent.right
                            text: "電源"
                            font.family: root.fontFamily
                            font.pixelSize: 10 * root.uiScale
                            color: ccWindow.cRed
                        }

                        Text {
                            anchors.right: parent.right
                            text: "POWER"
                            font.family: root.fontFamily
                            font.pixelSize: 8 * root.uiScale
                            color: ccWindow.cDim
                        }
                    }
                }
            }
        }
    }
}
