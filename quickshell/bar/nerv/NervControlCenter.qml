import Quickshell
import Quickshell.Io
import QtQuick

// nerv control center -- simplified version, less color, cleaner layout
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

    // main frame
    Rectangle {
        id: frame
        anchors.centerIn: parent
        width: 520 * root.uiScale
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

            // header
            Row {
                width: parent.width
                spacing: 8 * root.uiScale

                Text {
                    text: "nerv@hq"
                    font.family: root.fontFamily
                    font.pixelSize: 12 * root.uiScale
                    color: ccWindow.cRed
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ":"
                    font.family: root.fontFamily
                    font.pixelSize: 12 * root.uiScale
                    color: ccWindow.cDim
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "control-center"
                    font.family: root.fontFamily
                    font.pixelSize: 12 * root.uiScale
                    color: ccWindow.cDim
                }

                Item { width: parent.width - headerRow.implicitWidth; height: 1 }

                Text {
                    id: headerRow
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.dateTimeText.toUpperCase()
                    font.family: root.fontFamily
                    font.pixelSize: 11 * root.uiScale
                    color: ccWindow.cDim
                }
            }

            Rectangle { width: parent.width; height: 1; color: ccWindow.cRedDim }

            // toggles row
            Row {
                width: parent.width
                spacing: 8 * root.uiScale

                Repeater {
                    model: [
                        { name: "wifi", on: root.wifiName !== "", fn: "toggleWifi" },
                        { name: "bt", on: root.bluetoothEnabled, fn: "toggleBluetooth" },
                        { name: "nl", on: root.isNightLightEnabled, fn: "toggleNightLight" },
                        { name: "dnd", on: root.isDndEnabled, fn: "toggleDnd" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        width: (parent.width - 3 * 8 * root.uiScale) / 4
                        height: 32 * root.uiScale
                        radius: 2 * root.uiScale
                        color: modelData.on ? Qt.rgba(0.616, 0.039, 0.071, 0.15) : "transparent"
                        border.width: 1
                        border.color: modelData.on ? ccWindow.cRed : ccWindow.cRedDim

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.name
                                font.family: root.fontFamily
                                font.pixelSize: 10 * root.uiScale
                                color: modelData.on ? ccWindow.cWhite : ccWindow.cDim
                            }

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 6 * root.uiScale
                                height: 2 * root.uiScale
                                radius: 1
                                color: modelData.on ? ccWindow.cRed : ccWindow.cRedDim
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root[modelData.fn]()
                        }
                    }
                }
            }

            // sliders
            Column {
                width: parent.width
                spacing: 10 * root.uiScale

                Repeater {
                    model: [
                        { name: "vol", val: root.isVolumeMuted ? "muted" : (root.volume >= 0 ? root.volume + "%" : "--"), level: root.isVolumeMuted ? 0 : root.volume },
                        { name: "lux", val: root.brightnessLevel >= 0 ? root.brightnessLevel + "%" : "--", level: root.brightnessLevel }
                    ]

                    delegate: Column {
                        required property var modelData
                        width: parent.width
                        spacing: 4 * root.uiScale

                        Row {
                            width: parent.width

                            Text {
                                text: modelData.name
                                font.family: root.fontFamily
                                font.pixelSize: 10 * root.uiScale
                                color: ccWindow.cDim
                            }

                            Item { width: parent.width - sliderLabel.implicitWidth - sliderVal.implicitWidth - 16 * root.uiScale; height: 1 }

                            Text {
                                id: sliderVal
                                text: modelData.val
                                font.family: root.fontFamily
                                font.pixelSize: 10 * root.uiScale
                                color: ccWindow.cText
                            }
                        }

                        Rectangle {
                            id: sliderLabel
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
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: ccWindow.cRedDim }

            // status
            Row {
                width: parent.width
                spacing: 16 * root.uiScale

                Column {
                    width: parent.width * 0.5
                    spacing: 4 * root.uiScale

                    Repeater {
                        model: [
                            { k: "bat", v: (root.batteryLevel >= 0 ? root.batteryLevel + "%" : "--") + (root.batteryStatus === "Charging" ? " +" : "") },
                            { k: "net", v: root.wifiName === "" ? "offline" : root.wifiName },
                            { k: "up", v: ccWindow.uptimeText },
                            { k: "ram", v: ccWindow.ramText }
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

                Column {
                    width: parent.width * 0.5
                    spacing: 4 * root.uiScale

                    Repeater {
                        model: [
                            { k: "scr", v: "shift+s" },
                            { k: "rec", v: "ctrl+f10" },
                            { k: "wall", v: "w" }
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

            Rectangle { width: parent.width; height: 1; color: ccWindow.cRedDim }

            // power row
            Row {
                width: parent.width
                spacing: 0

                Repeater {
                    model: ["lock", "suspend", "logout", "reboot", "shutdown"]

                    delegate: Rectangle {
                        required property string modelData
                        width: (parent.width) / 5
                        height: 28 * root.uiScale
                        color: powerMa.containsMouse ? Qt.rgba(0.616, 0.039, 0.071, 0.2) : "transparent"

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 1
                            color: ccWindow.cRedDim
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.family: root.fontFamily
                            font.pixelSize: 10 * root.uiScale
                            color: powerMa.containsMouse ? ccWindow.cWhite : ccWindow.cDim
                        }

                        MouseArea {
                            id: powerMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ccWindow.powerAction(modelData)
                        }
                    }
                }
            }
        }
    }
}
