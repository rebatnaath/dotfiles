import Quickshell
import Quickshell.I3
import QtQuick
import "../components"

// The "lain" bar: slim full-width strip pinned to the top regardless of the
// global barSide setting. Background is the darkest color of the live
// wallpaper palette; no shadow, no border. Workspaces on the left (the
// sidebar continues this bar visually to the true screen edge), window
// title centered, icon+number status group on the right that opens the
// quick menu.
BarFace {
    id: lainBar

    faceHeight: 38 * root.uiScale
    faceColor: root.darkestColor
    showBorder: false
    showShadow: false
    sideInset: 0
    side: "top"
    marginTop: 0
    marginBottom: 0
    // Span from the true screen edge: dropping the left anchor means the
    // sidebar's left exclusive zone can't push us right. A separate invisible
    // spacer surface (shell.qml) reserves the top strip instead -- sway only
    // honours exclusive zones on surfaces anchored to exactly one horizontal
    // pair, which this window can't be.
    anchorLeft: false
    faceWidth: Quickshell.screens[0].width
    exclusionMode: ExclusionMode.Ignore
    readonly property color fgText: root.getColor("fg", "#c9cfdd")
    readonly property color dimText: root.getColor("muted", "#58627a")

    function batteryGlyph() {
        var level = root.batteryLevel
        if (level < 0) return "󰂑"
        if (root.batteryStatus === "Charging") {
            if (level < 20) return "󰢜"
            if (level < 40) return "󰂇"
            if (level < 60) return "󰂉"
            if (level < 80) return "󰂊"
            if (level < 90) return "󰂋"
            return "󰂅"
        }
        if (level < 10) return "󰂎"
        if (level < 20) return "󰁺"
        if (level < 40) return "󰁼"
        if (level < 60) return "󰁾"
        if (level < 80) return "󰂀"
        if (level < 100) return "󰂂"
        return "󰁹"
    }

    // Workspaces on the left.
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 12 * root.uiScale
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6 * root.uiScale

        Repeater {
            model: workspaceModel

            delegate: Rectangle {
                required property var modelData
                readonly property bool isActive: modelData.active
                height: 20 * root.uiScale
                width: wsText.implicitWidth + 8 * root.uiScale
                radius: root.frameRadius / 2
                color: isActive ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.16) : "transparent"

                Text {
                    id: wsText
                    anchors.centerIn: parent
                    text: modelData.id
                    font.family: root.fontFamily
                    font.pixelSize: 11 * root.uiScale
                    font.bold: isActive
                    color: isActive ? root.getColor("accent", "#ffb691") : lainBar.dimText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: I3.dispatch("workspace " + modelData.id)
                }
            }
        }
    }

    // Focused window title, centered.
    Text {
        width: Math.min(implicitWidth, parent.width * 0.4)
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideMiddle
        text: root.windowTitle === "" ? "present day... present time" : root.windowTitle
        font.family: root.fontFamily
        font.pixelSize: 11 * root.uiScale
        color: lainBar.dimText
    }

    // Status group on the right: battery / volume / clock icons + numbers.
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 12 * root.uiScale
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10 * root.uiScale

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: lainBar.batteryGlyph()
            font.family: root.fontFamily
            font.pixelSize: 15 * root.uiScale
            color: (root.batteryStatus !== "Charging" && root.batteryLevel <= 15 && root.batteryLevel >= 0)
                ? "#ff6b6b" : lainBar.fgText
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.batteryLevel >= 0 ? root.batteryLevel + "%" : "--"
            font.family: root.fontFamily
            font.pixelSize: 11 * root.uiScale
            color: lainBar.dimText
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            // fa-volume-up / fa-volume-off
            text: root.isVolumeMuted ? "\uF026" : "\uF028"
            font.family: root.fontFamily
            font.pixelSize: 15 * root.uiScale
            color: root.isVolumeMuted ? lainBar.dimText : lainBar.fgText
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.isVolumeMuted && root.volume >= 0
            text: root.volume + "%"
            font.family: root.fontFamily
            font.pixelSize: 11 * root.uiScale
            color: lainBar.dimText
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            // fa-clock-o
            text: "\uF017"
            font.family: root.fontFamily
            font.pixelSize: 15 * root.uiScale
            color: lainBar.fgText

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.isQuickMenuOpen = !root.isQuickMenuOpen
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.dateTimeText
            font.family: root.fontFamily
            font.pixelSize: 11 * root.uiScale
            color: lainBar.fgText

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.isQuickMenuOpen = !root.isQuickMenuOpen
            }
        }
    }
}
