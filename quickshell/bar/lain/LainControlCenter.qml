import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import "../components"

// Lain control center -- faithful port of the LAIN//control-center mockup
// (gap-grid toggle tiles, glowing active strips, label-above-slider rows,
// centred media player, action grid). Colours follow the live wallpaper
// palette instead of the mockup's fixed purple.
PanelWindow {
    id: ccWindow

    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    visible: (root.isQuickMenuOpen || root.lainPowerOpen) && root.activeBar === "lain"
    anchors { top: true; left: true; right: true; bottom: true }


    readonly property int barH: 38 * root.uiScale
    readonly property color lineColor: root.withAlpha(root.getColor("muted", "#58627a"), 0.4)
    // hex string, not color -- it gets fed back into mixHex()
    readonly property string surfaceColor: root.mixHex(root.darkestColor, root.getColor("fg", "#c9cfdd"), 0.04)

    Process { id: mediaActionProc }
    Process { id: screenshotProc }
    Process { id: recToggleProc }
    Process { id: powerOffProc }
    Process { id: powerActionProc }

    function mediaAction(action) {
        mediaActionProc.command = [root.swayScriptsDir + "/media-control", action]
        mediaActionProc.startDetached()
        root.mediaResync.restart()
    }

    // Click outside the card closes.
    MouseArea {
        anchors.fill: parent
        onClicked: root.isQuickMenuOpen = false
    }

    // ---- power menu overlay (mockup .overlay/.power) ----
    Rectangle {
        anchors.fill: parent
        visible: root.lainPowerOpen
        color: root.withAlpha("#050509", 0.62)

        MouseArea {
            anchors.fill: parent
            onClicked: root.lainPowerOpen = false
        }

        Rectangle {
            id: powerCard
            anchors.centerIn: parent
            width: 570 * root.uiScale
            height: powerContent.implicitHeight + 50 * root.uiScale
            // pinned dark like the mockup, independent of the wallpaper
            color: "#07070b"
            border.width: 1 * root.uiScale
            border.color: root.withAlpha(root.getColor("muted", "#58627a"), 0.5)

            // left accent gradient strip (:before)
            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: 2 * root.uiScale
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.6) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                opacity: 0.4
            }

            MouseArea { anchors.fill: parent; onPressed: (mouse) => mouse.accepted = true }

            Column {
                id: powerContent
                anchors { left: parent.left; right: parent.right; top: parent.top }
                anchors.margins: 25 * root.uiScale
                spacing: 15 * root.uiScale

                Item {
                    width: parent.width
                    height: Math.max(titleCol.implicitHeight, closeText.implicitHeight)

                    Row {
                        id: titleCol
                        anchors.left: parent.left
                        spacing: 0

                        Text {
                            text: "connection ending"
                            font.family: root.fontFamily
                            font.pixelSize: 19 * root.uiScale
                            font.weight: Font.Medium
                            color: root.getColor("fg", "#c9cfdd")
                        }

                        // blinking cursor, same as the control-center header
                        Text {
                            anchors.baseline: parent.children[0].baseline
                            text: "_"
                            font.family: root.fontFamily
                            font.pixelSize: 19 * root.uiScale
                            color: root.getColor("accent", "#ffb691")

                            SequentialAnimation on opacity {
                                running: root.lainPowerOpen
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.2; duration: 550 }
                                NumberAnimation { to: 1.0; duration: 550 }
                            }
                        }
                    }

                    Text {
                        id: closeText
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\u00D7"
                        font.family: root.fontFamily
                        font.pixelSize: 22 * root.uiScale
                        color: root.getColor("muted", "#58627a")

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.lainPowerOpen = false
                        }
                    }
                }

                Divider {}

                Rectangle {
                    width: parent.width
                    height: 2 * 126 * root.uiScale + 1 * root.uiScale + 2 * root.uiScale
                    color: ccWindow.lineColor
                    border.width: 1 * root.uiScale
                    border.color: ccWindow.lineColor

                    Grid {
                        x: 1 * root.uiScale; y: 1 * root.uiScale
                        width: parent.width - 2 * root.uiScale
                        columns: 2
                        spacing: 1 * root.uiScale

                        Repeater {
                            model: [
                                { glyph: "\uF011", name: "SHUT DOWN", desc: "terminate session", cmd: "poweroff" },
                                { glyph: "\uF021", name: "RESTART", desc: "reload machine", cmd: "reboot" },
                                { glyph: "\uF08B", name: "LOG OUT", desc: "disconnect user", cmd: "exit" },
                                { glyph: "\uF186", name: "SUSPEND", desc: "low power state", cmd: "suspend" }
                            ]

                            delegate: Rectangle {
                                id: powerTile
                                required property var modelData
                                width: (parent.width - parent.spacing) / 2
                                height: 126 * root.uiScale
                                color: tileHover.hovered
                                    ? root.mixHex(ccWindow.surfaceColor, root.getColor("fg", "#c9cfdd"), 0.06)
                                    : ccWindow.surfaceColor

                                Column {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 18 * root.uiScale
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 6 * root.uiScale

                                    Text {
                                        text: powerTile.modelData.glyph
                                        font.family: root.fontFamily
                                        font.pixelSize: 27 * root.uiScale
                                        color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.85)
                                    }

                                    Text {
                                        text: powerTile.modelData.name
                                        font.family: root.fontFamily
                                        font.pixelSize: 10 * root.uiScale
                                        font.weight: Font.Medium
                                        color: root.getColor("fg", "#c9cfdd")
                                    }

                                    Text {
                                        text: powerTile.modelData.desc
                                        font.family: root.fontFamily
                                        font.pixelSize: 8 * root.uiScale
                                        color: root.withAlpha(root.getColor("muted", "#58627a"), 0.85)
                                    }
                                }

                                MouseArea {
                                    id: tileHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var c = powerTile.modelData.cmd
                                        if (c === "exit")
                                            powerActionProc.command = ["swaymsg", "exit"]
                                        else
                                            powerActionProc.command = ["systemctl", c]
                                        powerActionProc.startDetached()
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: Math.max(footerLeft.implicitHeight, footerRight.implicitHeight)

                    Text {
                        id: footerLeft
                        anchors.left: parent.left
                        text: "lain@iwakura:~"
                        font.family: root.fontFamily
                        font.pixelSize: 7 * root.uiScale
                        font.letterSpacing: 0.7
                        color: root.withAlpha(root.getColor("muted", "#58627a"), 0.75)
                    }

                    Text {
                        id: footerRight
                        anchors.right: parent.right
                        text: "GLOBAL LINK // STABLE"
                        font.family: root.fontFamily
                        font.pixelSize: 7 * root.uiScale
                        font.letterSpacing: 0.7
                        color: root.withAlpha(root.getColor("muted", "#58627a"), 0.75)
                    }
                }
            }
        }
    }

    Rectangle {
        id: card
        visible: !root.lainPowerOpen
        x: parent.width - width - 12 * root.uiScale
        y: ccWindow.barH + 10 * root.uiScale
        width: 480 * root.uiScale
        height: contentColumn.implicitHeight + 36 * root.uiScale
        radius: 0
        // subtle vertical gradient like the mockup's linear-gradient card bg
        color: root.darkestColor

        RectangularShadow {
            anchors.fill: card
            radius: 0
            color: "#a0000000"
            blur: 40 * root.uiScale
            offset: Qt.vector2d(0, 10 * root.uiScale)
            visible: root.quickMenuShadow && root.activeBar !== "nerv"
        }

        AccentBorder {
            cornerRadius: 0
            thickness: 1 * root.uiScale
            frameColor: root.withAlpha(root.getColor("muted", "#58627a"), 0.55)
            visible: root.quickMenuBorder
        }

        // accent edge glow down the left side (:after in the css)
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1 * root.uiScale
            opacity: 0.45
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: root.getColor("accent", "#ffb691") }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => mouse.accepted = true
        }

        Column {
            id: contentColumn
            anchors {
                left: parent.left; right: parent.right; top: parent.top
                margins: 20 * root.uiScale
            }
            spacing: 14 * root.uiScale

            // ---- header ----
            Item {
                width: parent.width
                height: 26 * root.uiScale

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "control center"
                        font.family: root.fontFamily
                        font.pixelSize: 19 * root.uiScale
                        font.weight: Font.Medium
                        color: root.getColor("fg", "#c9cfdd")
                    }

                    Text {
                        anchors.baseline: parent.children[0].baseline
                        text: "_"
                        font.family: root.fontFamily
                        font.pixelSize: 19 * root.uiScale
                        color: root.getColor("accent", "#ffb691")

                        SequentialAnimation on opacity {
                            running: ccWindow.visible
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.2; duration: 550 }
                            NumberAnimation { to: 1.0; duration: 550 }
                        }
                    }
                }

                // status readout pinned to the right edge
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 9 * root.uiScale

                    // signal bars: lit while wifi is connected
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2 * root.uiScale

                        Repeater {
                            model: [4, 6, 9, 12]

                            delegate: Rectangle {
                                required property int index
                                required property var modelData
                                width: 2 * root.uiScale
                                height: modelData * root.uiScale
                                anchors.verticalCenter: parent.verticalCenter
                                color: root.wifiName !== ""
                                    ? root.getColor("accent", "#ffb691")
                                    : root.withAlpha(root.getColor("muted", "#58627a"), 0.6)
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (root.batteryLevel >= 0 ? root.batteryLevel : "--") + "%"
                        font.family: root.fontFamily
                        font.pixelSize: 10 * root.uiScale
                        color: root.getColor("muted", "#58627a")
                    }

                    // css .battery widget: outline + level fill + tip
                    Item {
                        width: 18 * root.uiScale
                        height: 9 * root.uiScale
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            id: batteryBody
                            anchors.fill: parent
                            color: "transparent"
                            border.width: 1
                            border.color: root.withAlpha(root.getColor("muted", "#58627a"), 0.8)

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1 * root.uiScale
                                width: Math.max(0, (parent.width - 2 * root.uiScale)
                                    * Math.min(100, Math.max(0, root.batteryLevel)) / 100)
                                color: root.getColor("accent", "#ffb691")
                            }
                        }

                        Rectangle {
                            anchors.right: batteryBody.left
                            anchors.rightMargin: -3 * root.uiScale
                            anchors.verticalCenter: parent.verticalCenter
                            width: 2 * root.uiScale
                            height: 4 * root.uiScale
                            color: root.withAlpha(root.getColor("muted", "#58627a"), 0.8)
                        }
                    }
                }
            }

            Divider {}

            // ---- toggle tiles (gap-grid: container bg shows as the lines) ----
            Rectangle {
                width: parent.width
                height: tileGrid.implicitHeight + 2 * root.uiScale
                color: ccWindow.lineColor
                border.width: 1 * root.uiScale
                border.color: ccWindow.lineColor

                Grid {
                    id: tileGrid
                    x: 1 * root.uiScale; y: 1 * root.uiScale
                    width: parent.width - 2 * root.uiScale
                    columns: 2
                    spacing: 1 * root.uiScale

                    Repeater {
                        model: [
                            { glyph: "\uF0AC", name: "WIRED", checked: root.wifiName !== "", busy: root.isWifiConnecting, onLabel: "CONNECTED", offLabel: "DISCONNECTED", fn: "toggleWifi" },
                            { glyph: "\uF294", name: "BLUETOOTH", checked: root.bluetoothEnabled, busy: root.isBluetoothConnecting, onLabel: "ON", offLabel: "OFF", fn: "toggleBluetooth" },
                            { glyph: "\uF186", name: "NIGHT LIGHT", checked: root.isNightLightEnabled, busy: false, onLabel: "ON", offLabel: "OFF", fn: "toggleNightLight" },
                            { glyph: "\u2212", name: "DO NOT DISTURB", checked: root.isDndEnabled, busy: false, onLabel: "ON", offLabel: "OFF", fn: "toggleDnd" }
                        ]

                        delegate: Rectangle {
                            id: tile
                            required property var modelData
                            width: (tileGrid.width - tileGrid.spacing) / 2
                            height: 84 * root.uiScale
                            color: tileMouse.hovered
                                ? root.mixHex(ccWindow.surfaceColor, root.getColor("fg", "#c9cfdd"), 0.05)
                                : ccWindow.surfaceColor

                            // active: accent wash + glowing 2px strip on top
                            Rectangle {
                                visible: tile.modelData.checked
                                anchors { top: parent.top; left: parent.left; right: parent.right }
                                height: 2 * root.uiScale
                                color: root.getColor("accent", "#ffb691")

                                RectangularShadow {
                                    anchors.fill: parent
                                    radius: 0
                                    blur: 10 * root.uiScale
                                    color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.45)
                                }
                            }

                            Rectangle {
                                visible: tile.modelData.checked
                                anchors.fill: parent
                                color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.07)
                            }

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 12 * root.uiScale
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6 * root.uiScale

                                Text {
                                    text: tile.modelData.glyph
                                    font.family: root.fontFamily
                                    font.pixelSize: 20 * root.uiScale
                                    color: tile.modelData.checked
                                        ? root.getColor("accent", "#ffb691") : root.withAlpha(root.getColor("muted", "#58627a"), 0.9)
                                }

                                Text {
                                    text: tile.modelData.name
                                    font.family: root.fontFamily
                                    font.pixelSize: 9 * root.uiScale
                                    font.letterSpacing: 0.65
                                    color: root.getColor("fg", "#c9cfdd")
                                }

                                Text {
                                    text: tile.modelData.busy
                                        ? "CONNECTING" : (tile.modelData.checked ? tile.modelData.onLabel : tile.modelData.offLabel)
                                    font.family: root.fontFamily
                                    font.pixelSize: 8 * root.uiScale
                                    color: tile.modelData.checked || tile.modelData.busy
                                        ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.85)
                                        : root.withAlpha(root.getColor("muted", "#58627a"), 0.8)
                                }
                            }

                            MouseArea {
                                id: tileMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root[tile.modelData.fn]()
                            }
                        }
                    }
                }
            }

            // ---- control rows: glyph | label-over-slider | chevron ----
            Repeater {
                model: [
                    { glyph: "\u25D6", label: "VOLUME", kind: "volume" },
                    { glyph: "\u263C", label: "BRIGHTNESS", kind: "brightness" }
                ]

                delegate: Item {
                    id: controlRow
                    required property var modelData
                    width: parent.width
                    height: 52 * root.uiScale

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: controlRow.modelData.glyph
                        font.family: root.fontFamily
                        font.pixelSize: 22 * root.uiScale
                        color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.8)
                    }

                    Item {
                        id: rangeWrap
                        anchors.left: parent.left
                        anchors.leftMargin: 34 * root.uiScale
                        anchors.right: parent.right
                        anchors.rightMargin: 24 * root.uiScale
                        anchors.verticalCenter: parent.verticalCenter
                        height: 30 * root.uiScale

                        property bool isVolume: controlRow.modelData.kind === "volume"
                        property real currentValue: isVolume
                            ? (root.isVolumeMuted || root.volume < 0 ? 0 : root.volume)
                            : root.brightnessLevel

                        Item {
                            id: labelRow
                            width: parent.width
                            height: Math.max(labelLeft.implicitHeight, labelRight.implicitHeight)

                            Text {
                                id: labelLeft
                                anchors.left: parent.left
                                text: controlRow.modelData.label
                                font.family: root.fontFamily
                                font.pixelSize: 8 * root.uiScale
                                font.letterSpacing: 0.5
                                color: root.getColor("muted", "#58627a")
                            }

                            Text {
                                id: labelRight
                                anchors.right: parent.right
                                text: rangeWrap.isVolume
                                    ? (root.isVolumeMuted ? "MUTED" : (root.volume < 0 ? "--" : root.volume + ""))
                                    : (root.brightnessLevel < 0 ? "--" : root.brightnessLevel + "")
                                font.family: root.fontFamily
                                font.pixelSize: 8 * root.uiScale
                                color: root.getColor("muted", "#58627a")
                            }
                        }

                        Rectangle {
                            id: track
                            anchors.top: labelRow.bottom
                            anchors.topMargin: 8 * root.uiScale
                            width: parent.width
                            height: 2 * root.uiScale
                            color: root.withAlpha(root.getColor("muted", "#58627a"), 0.35)

                            Rectangle {
                                id: fillBar
                                height: parent.height
                                width: parent.width * Math.max(0, Math.min(100, rangeWrap.currentValue)) / 100
                                color: trackMouse.hovered
                                    ? root.mixHex(root.getColor("accent", "#ffb691"), "#ffffff", 0.2)
                                    : root.getColor("accent", "#ffb691")
                            }

                            Rectangle {
                                width: 11 * root.uiScale
                                height: 11 * root.uiScale
                                radius: width / 2
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, Math.min(parent.width - width, fillBar.width - width / 2))
                                border.width: 2 * root.uiScale
                                border.color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.85)
                                color: root.getColor("accent", "#ffb691")

                                RectangularShadow {
                                    anchors.fill: parent
                                    radius: width / 2
                                    blur: 8 * root.uiScale
                                    color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.45)
                                }
                            }

                            MouseArea {
                                id: trackMouse
                                anchors { fill: parent; topMargin: -8; bottomMargin: -8 }
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                function valueAt(mouseX) {
                                    return Math.max(0, Math.min(100, mouseX / track.width * 100))
                                }
                                onPressed: (mouse) => apply(valueAt(mouse.x), true)
                                onPositionChanged: (mouse) => { if (pressed) apply(valueAt(mouse.x), true) }
                                onReleased: (mouse) => apply(valueAt(mouse.x), false)

                                function apply(v, preview) {
                                    if (rangeWrap.isVolume) {
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

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\u203A"
                        font.family: root.fontFamily
                        font.pixelSize: 16 * root.uiScale
                        color: root.withAlpha(root.getColor("muted", "#58627a"), 0.8)
                    }
                }
            }

            // ---- media ----
            Column {
                width: parent.width
                spacing: 12 * root.uiScale
                visible: root.mediaStatus !== "None"

                Rectangle { width: parent.width; height: 1 * root.uiScale; color: ccWindow.lineColor }

                Text {
                    text: "NOW PLAYING // " + root.mediaStatus.toUpperCase()
                    font.family: root.fontFamily
                    font.pixelSize: 8 * root.uiScale
                    font.letterSpacing: 1
                    color: root.withAlpha(root.getColor("muted", "#58627a"), 0.9)
                }

                Row {
                    width: parent.width
                    spacing: 13 * root.uiScale

                    Rectangle {
                        width: 76 * root.uiScale
                        height: 76 * root.uiScale
                        color: root.mixHex(ccWindow.surfaceColor, root.getColor("accent", "#ffb691"), 0.15)
                        clip: true

                        Image {
                            id: artImage
                            anchors.fill: parent
                            source: root.mediaArtUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                            cache: false
                            visible: root.mediaArtUrl !== "" && status === Image.Ready
                        }

                        Column {
                            visible: !artImage.visible

                            Repeater {
                                model: 19

                                delegate: Rectangle {
                                    required property int index
                                    width: 76 * root.uiScale
                                    height: 4 * root.uiScale
                                    color: index % 2 === 0 ? "transparent" : root.withAlpha(root.getColor("fg", "#c9cfdd"), 0.05)
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "\uF036"
                                font.family: root.fontFamily
                                font.pixelSize: 22 * root.uiScale
                                color: root.withAlpha(root.getColor("muted", "#58627a"), 0.6)
                            }
                        }
                    }

                    Item {
                        width: parent.width - 76 * root.uiScale - 13 * root.uiScale
                        height: 76 * root.uiScale

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            spacing: 6 * root.uiScale

                            Text {
                                width: parent.width
                                text: root.mediaTitle || root.mediaName || "Unknown"
                                font.family: root.fontFamily
                                font.pixelSize: 17 * root.uiScale
                                elide: Text.ElideRight
                                color: root.getColor("fg", "#c9cfdd")
                            }

                            Text {
                                width: parent.width
                                text: root.mediaArtist || "Unknown Artist"
                                font.family: root.fontFamily
                                font.pixelSize: 10 * root.uiScale
                                elide: Text.ElideRight
                                color: root.getColor("muted", "#58627a")
                            }

                            Item {
                                width: parent.width
                                height: trackLine.height + 18 * root.uiScale

                                Rectangle {
                                    id: trackLine
                                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                    height: 2 * root.uiScale
                                    color: root.withAlpha(root.getColor("muted", "#58627a"), 0.35)

                                    Rectangle {
                                        width: parent.width * 0.31
                                        height: parent.height
                                        color: root.getColor("accent", "#ffb691")
                                    }
                                }
                            }
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 44 * root.uiScale

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uF048"
                        font.family: root.fontFamily
                        font.pixelSize: 18 * root.uiScale
                        color: root.withAlpha(root.getColor("muted", "#58627a"), 0.9)

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ccWindow.mediaAction("Previous")
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.mediaStatus === "Playing" ? "\uF04C" : "\uF04B"
                        font.family: root.fontFamily
                        font.pixelSize: 18 * root.uiScale
                        color: root.getColor("fg", "#c9cfdd")

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleMediaPlay()
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uF051"
                        font.family: root.fontFamily
                        font.pixelSize: 18 * root.uiScale
                        color: root.withAlpha(root.getColor("muted", "#58627a"), 0.9)

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ccWindow.mediaAction("Next")
                        }
                    }
                }
            }

            // ---- actions (gap-grid) ----
            Rectangle {
                width: parent.width
                height: 53 * root.uiScale + 2 * root.uiScale
                color: ccWindow.lineColor
                border.width: 1 * root.uiScale
                border.color: ccWindow.lineColor

                Grid {
                    id: actionGrid
                    x: 1 * root.uiScale; y: 1 * root.uiScale
                    width: parent.width - 2 * root.uiScale
                    columns: 3
                    spacing: 1 * root.uiScale

                    Repeater {
                        model: [
                            { glyph: "\uF108", label: "SCREEN CAST", danger: false },
                            { glyph: "\uF030", label: "SCREENSHOT", danger: false },
                            { glyph: "\uF011", label: "POWER OFF", danger: true }
                        ]

                        delegate: Rectangle {
                            id: actionButton
                            required property var modelData
                            property bool armed: false
                            width: (actionGrid.width - actionGrid.spacing * 2) / 3
                            height: 53 * root.uiScale
                            color: actionMouse.hovered
                                ? root.mixHex(ccWindow.surfaceColor, root.getColor("fg", "#c9cfdd"), 0.06)
                                : ccWindow.surfaceColor

                            Row {
                                anchors.centerIn: parent
                                spacing: 6 * root.uiScale

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: actionButton.modelData.glyph
                                    font.family: root.fontFamily
                                    font.pixelSize: 13 * root.uiScale
                                    color: actionButton.armed
                                        ? "#ff6b6b"
                                        : root.withAlpha(root.getColor("accent", "#ffb691"), 0.9)
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: actionButton.modelData.label
                                    font.family: root.fontFamily
                                    font.pixelSize: 8 * root.uiScale
                                    font.letterSpacing: 0.4
                                    color: actionButton.armed
                                        ? "#ff6b6b" : root.getColor("muted", "#58627a")
                                }
                            }

                            MouseArea {
                                id: actionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (actionButton.modelData.label === "SCREEN CAST") {
                                        recToggleProc.command = [root.swayScriptsDir + "/rec-toggle.sh"]
                                        recToggleProc.startDetached()
                                        root.isQuickMenuOpen = false
                                    } else if (actionButton.modelData.label === "SCREENSHOT") {
                                        screenshotProc.command = ["bash", "-c",
                                            'mkdir -p "$HOME/Pictures/Screenshots/sway" && grim -g "$(slurp)" - | tee "$HOME/Pictures/Screenshots/sway/screenshot-$(date +%Y-%m-%d_%H%M%S).png" | wl-copy']
                                        screenshotProc.startDetached()
                                        root.isQuickMenuOpen = false
                                    } else {
                                        root.lainPowerOpen = true
                                    }
                                }
}
}
}
}
}
}
}
}
