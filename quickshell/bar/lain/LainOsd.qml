import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects

// Lain OSD -- port of the mockup's .osd cards. Compact card in the top-right
// corner below the bar: bordered glyph box on the left, label+value header,
// thin glowing bar, channel caption below. Feeds off the same state file as
// the default OSD (~/.cache/quickshell-osd.json, written by sway/scripts/osd).
PanelWindow {
    id: osdWindow

    visible: root.activeBar === "lain" && card.opacity > 0
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    // compact card pinned under the bar in the top-right corner
    anchors { top: true; right: true }
    margins.top: (38 + 10) * root.uiScale
    margins.right: 12 * root.uiScale
    implicitWidth: 260 * root.uiScale
    implicitHeight: cardColumn.implicitHeight + 32 * root.uiScale
    // only the card itself takes input; the rest is click-through
    mask: Region { item: card }

    FileView {
        id: osdStateFile
        path: "/home/oryza/.cache/quickshell-osd.json"
        watchChanges: true
        onFileChanged: osdStateFile.reload()
        onTextChanged: osdWindow.handleOsdState()
    }

    property real osdLevel: 0
    property string osdValueText: "--"
    // skip the preload read so bar restarts don't flash stale values
    property bool firstRead: true
    property string lastValue: ""
    property string osdType: "volume"

    function handleOsdState() {
        var text = osdStateFile.text().trim()
        if (text === "") return
        if (osdWindow.firstRead) {
            osdWindow.firstRead = false
            osdWindow.lastValue = text
            return
        }
        if (text === osdWindow.lastValue) return
        osdWindow.lastValue = text
        try {
            var state = JSON.parse(text)
            if (state.type !== "volume" && state.type !== "brightness") return
            osdWindow.osdType = state.type
            if (state.type === "volume") {
                osdGlyph.text = state.state === "muted" ? "\uF026" : "\u25D6"
                root.isVolumeMuted = state.state === "muted"
                root.volume = parseInt(state.value)
            } else {
                osdGlyph.text = "\u263C"
                root.brightnessLevel = parseInt(state.value)
            }
            osdValueText = state.value
            osdLevel = Math.max(0, Math.min(100, parseInt(state.value)))
            card.opacity = 1
            hideTimer.restart()
        } catch (e) { /* ignore malformed state */ }
    }

    Timer {
        id: hideTimer
        interval: 2200
        onTriggered: card.opacity = 0
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: parent.width - 2 * root.uiScale
        height: cardColumn.implicitHeight + 32 * root.uiScale
        opacity: 0
        radius: 0
        // linear-gradient(135deg,#120e18,#08070b) equivalent
        color: root.mixHex(root.darkestColor, root.getColor("fg", "#c9cfdd"), 0.04)
        border.width: 1 * root.uiScale
        border.color: root.withAlpha(root.getColor("muted", "#58627a"), 0.55)

        Behavior on opacity { NumberAnimation { duration: 180 } }

        Row {
            id: cardColumn
            anchors {
                left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                margins: 16 * root.uiScale
            }
            spacing: 16 * root.uiScale

            Rectangle {
                width: 44 * root.uiScale
                height: 44 * root.uiScale
                color: root.mixHex(root.darkestColor, root.getColor("fg", "#c9cfdd"), 0.03)
                border.width: 1 * root.uiScale
                border.color: root.withAlpha(root.getColor("muted", "#58627a"), 0.55)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: osdGlyph
                    anchors.centerIn: parent
                    text: "\u25D6"
                    font.family: root.fontFamily
                    font.pixelSize: 20 * root.uiScale
                    color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.9)
                }
            }

            Column {
                width: parent.width - 44 * root.uiScale - 16 * root.uiScale - 32 * root.uiScale
                spacing: 9 * root.uiScale

                Item {
                    id: osdHeader
                    width: parent.width
                    height: Math.max(labelText.implicitHeight, valueText.implicitHeight)

                    Text {
                        id: labelText
                        anchors.left: parent.left
                        text: osdWindow.osdType.toUpperCase()
                        font.family: root.fontFamily
                        font.pixelSize: 9 * root.uiScale
                        font.letterSpacing: 0.8
                        color: root.withAlpha(root.getColor("muted", "#58627a"), 0.95)
                    }

                    Text {
                        id: valueText
                        anchors.right: parent.right
                        text: osdWindow.osdValueText
                        font.family: root.fontFamily
                        font.pixelSize: 11 * root.uiScale
                        color: root.getColor("fg", "#c9cfdd")
                    }
                }

                Rectangle {
                    id: trackBar
                    width: parent.width
                    height: 4 * root.uiScale
                    color: root.withAlpha(root.getColor("muted", "#58627a"), 0.3)

                    Rectangle {
                        id: fillBar
                        width: parent.width * osdWindow.osdLevel / 100
                        height: parent.height
                        color: root.getColor("accent", "#ffb691")

                        RectangularShadow {
                            anchors.fill: parent
                            radius: 0
                            blur: 12 * root.uiScale
                            color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.45)
                        }
                    }
                }

            }
        }
    }
}
