import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import "../components"

// Lain-mode sidebar: full-height panel docked to the left edge, below the
// top bar. Placeholder image + title entries at the top (lain, wire,
// terminal, lain's diary, playlist, image board), power-off button pinned
// to the bottom. Only visible while lain is the active bar.
PanelWindow {
    id: sidebar

    visible: root.activeBar === "lain"
    color: root.darkestColor
    // Reserve space so tiled windows stay clear of the sidebar. Anchored all
    // the way up so its top strip continues the bar across the left edge
    // (same colour, same height -> seamless corner, no hole).
    exclusionMode: ExclusionMode.Auto
    anchors { left: true; top: true; bottom: true }
    implicitWidth: 130 * root.uiScale
    margins { top: 0; bottom: 0; left: 0 }

    // Sidebar entries: square image on top, title below. Drop PNGs named
    // <slug>.png into bar/lain/assets/ (64x64 or larger, square); until one
    // exists the letter placeholder shows instead.
    ListModel {
        id: entries
        ListElement { title: "lain"; letter: "L"; slug: "lain"; cmd: "nautilus ~" }
        ListElement { title: "wire"; letter: "W"; slug: "wire"; cmd: "xdg-open http://www.google.com" }
        ListElement { title: "terminal"; letter: ">"; slug: "terminal"; cmd: "kitty" }
        ListElement { title: "lain's diary"; letter: "D"; slug: "diary"; cmd: "" }
        ListElement { title: "playlist"; letter: "\u266B"; slug: "playlist"; cmd: "" }
        ListElement { title: "image board"; letter: "I"; slug: "imageboard"; cmd: "" }
    }

    // Launch a sidebar entry through the shell so ~ and URLs both work;
    // no-ops for entries without a command.
    function launch(slug) {
        for (var i = 0; i < entries.count; i++) {
            var e = entries.get(i)
            if (e.slug === slug && e.cmd !== "") {
                launcherProc.command = ["sh", "-c", e.cmd]
                launcherProc.startDetached()
                return
            }
        }
    }

    Process { id: launcherProc }

    Column {
        id: entryList
        anchors { left: parent.left; right: parent.right; top: parent.top }
        anchors.margins: 10 * root.uiScale
        // Clear the bar strip (34px) plus a little breathing room.
        anchors.topMargin: 38 * root.uiScale + 16 * root.uiScale
        spacing: 10 * root.uiScale

        Repeater {
            model: entries

            delegate: Rectangle {
                id: entryCard
                required property var modelData
                width: entryList.width - entryList.anchors.margins * 2
                height: iconBox.width + titleText.implicitHeight + 12 * root.uiScale
                radius: root.frameRadius / 2
                color: rowMouse.hovered
                    ? root.withAlpha(root.getColor("fg", "#c9cfdd"), 0.08) : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 6 * root.uiScale
                    spacing: 6 * root.uiScale

                    // Square image slot.
                    Rectangle {
                        id: iconBox
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 64 * root.uiScale
                        height: 64 * root.uiScale
                        radius: root.frameRadius / 2
                        color: "transparent"
                        clip: true

                        Image {
                            id: thumbImage
                            anchors.fill: parent
                            source: Qt.resolvedUrl("assets/" + entryCard.modelData.slug + ".png")
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                            visible: status === Image.Ready
                            // Tint the PNG with the workspace-highlight
                            // colour (accent), flipping to fg on hover.
                            layer.enabled: visible
                            layer.effect: MultiEffect {
                                colorization: 1.0
                                colorizationColor: rowMouse.hovered
                                    ? root.getColor("fg", "#c9cfdd")
                                    : root.getColor("accent", "#ffb691")
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: entryCard.modelData.letter
                            font.family: root.fontFamily
                            font.pixelSize: 18 * root.uiScale
                            font.bold: true
                            color: root.getColor("fg", "#c9cfdd")
                            visible: !parent.children[0].visible
                        }
                    }

                    Text {
                        id: titleText
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: entryCard.modelData.title
                        font.family: root.fontFamily
                        font.pixelSize: 11 * root.uiScale
                        elide: Text.ElideRight
                        // Center on the card (= icon axis), not the sidebar.
                        width: entryCard.width
                        horizontalAlignment: Text.AlignHCenter
                        color: rowMouse.hovered
                            ? root.getColor("fg", "#c9cfdd") : root.getColor("muted", "#58627a")
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sidebar.launch(entryCard.modelData.slug)
                }
            }
        }
    }

    // Power entry: same card shape as the others (square icon on top, label
    // below), pinned to the bottom.
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 10 * root.uiScale
        }
        height: powerIcon.width + powerLabel.implicitHeight + 12 * root.uiScale
        radius: root.frameRadius / 2
        color: powerMouse.hovered
            ? root.withAlpha(root.getColor("fg", "#c9cfdd"), 0.08) : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 6 * root.uiScale
            spacing: 6 * root.uiScale

            Rectangle {
                id: powerIcon
                width: 64 * root.uiScale
                height: 64 * root.uiScale
                radius: root.frameRadius / 2
                color: "transparent"

                Text {
                    id: powerIconText
                    anchors.centerIn: parent
                    // fa-power-off
                    text: "\uF011"
                    font.family: root.fontFamily
                    font.pixelSize: 34 * root.uiScale
                    // Tint like the entry thumbnails: accent normally, fg on hover.
                    color: powerMouse.hovered
                        ? root.getColor("fg", "#c9cfdd")
                        : root.getColor("accent", "#ffb691")
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
            }

            Text {
                id: powerLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: "power off"
                font.family: root.fontFamily
                font.pixelSize: 11 * root.uiScale
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: powerMouse.hovered
                    ? root.getColor("fg", "#c9cfdd") : root.getColor("muted", "#58627a")
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }

        MouseArea {
            id: powerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.lainPowerOpen = true
        }
    }
}
