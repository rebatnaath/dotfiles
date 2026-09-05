import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import "../components"

// OSD: flashes volume/brightness, fades out
PanelWindow {
    id: osdWindow
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    // top-right when bar is on top or full-width, bottom-right otherwise
    readonly property bool atTop: (root.barSide === "top" || root.barFullWidth)
    anchors {
        top: atTop
        bottom: !atTop
        right: true
    }
    margins {
        top: atTop ? (root.barFullWidth ? 62 * root.uiScale : 9 * root.uiScale) : 0
        bottom: atTop ? 0 : 9 * root.uiScale
        right: root.windowGap * root.uiScale
    }
    implicitWidth: osdCard.implicitWidth
    implicitHeight: osdCard.implicitHeight + 8
    visible: osdCard.opacity > 0

    FileView {
        id: osdStateFile
        path: Quickshell.env("HOME") + "/.cache/quickshell-osd.json"
        watchChanges: true
        // reload on file change
        onFileChanged: osdStateFile.reload()
        onTextChanged: osdWindow.handleOsdState()
    }

    // shadow (same as bar)
    RectangularShadow {
        anchors.fill: osdCard
        radius: 0
        color: "#000000"
        blur: 0
        spread: 0
        offset: Qt.vector2d(8 * root.uiScale, 8 * root.uiScale)
        visible: root.osdShadow
    }

    Rectangle {
        id: osdCard
        // start hidden
        opacity: 0
        height: 46 * root.uiScale
        implicitHeight: 46
        // 8px gap for shadow, aligns with tiled window edge
        anchors {
            left: parent.left
            right: parent.right
            rightMargin: 8 * root.uiScale
            bottom: parent.bottom
            bottomMargin: 8 * root.uiScale
        }
        implicitWidth: osdRow.implicitWidth + 40
        radius: root.frameRadius
        color: root.getColor("bg", "#1a120e")

        AccentBorder {
            cornerRadius: root.frameRadius
            visible: root.osdBorder
        }

        Row {
            id: osdRow
            anchors.centerIn: parent
            spacing: 12

            Text {
                id: osdIcon
                text: ""
                font.family: root.fontFamily
                font.pixelSize: 19 * root.uiScale
                color: root.getColor("accent", "#ffb691")
                anchors.verticalCenter: parent.verticalCenter
            }

            // level track + fill
            Rectangle {
                id: osdTrack
                width: 160 * root.uiScale
                height: 10 * root.uiScale
                radius: 5
                color: root.withAlpha(root.getColor("muted", "#a08d85"), 0.22)
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    id: osdFill
                    width: osdTrack.width * (osdWindow.osdLevel / 100)
                    height: parent.height
                    radius: 5
                    color: root.getColor("accent", "#ffb691")
                    Behavior on width {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }
            }

            Text {
                id: osdValue
                text: "50%"
                font.family: root.fontFamily
                font.pixelSize: 17 * root.uiScale
                // fixed width for "100%"
                width: 44 * root.uiScale
                color: root.getColor("fg", "#f0dfd8")
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Timer {
        id: osdHideTimer
        interval: 3000
        onTriggered: osdCard.opacity = 0
    }

    // exposed for notification popup to mirror
    readonly property real cardWidth: osdCard.implicitWidth
    property real osdLevel: 0
    // Skip the first file read (preload) and duplicate reads to avoid
    // showing stale OSD on startup. The trade-off is that a volume/brightness
    // change happening exactly at startup is missed — acceptable since the
    // user can see the new level in the bar immediately.
    property bool firstRead: true
    property string lastValue: ""

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
            var parsedValue = parseInt(state.value, 10)
            if (isNaN(parsedValue)) return
            if (state.type === "volume") {
                osdIcon.text = state.state === "muted" ? "ﱝ" : ""
                root.isVolumeMuted = state.state === "muted"
                root.volume = parsedValue
            } else if (state.type === "brightness") {
                osdIcon.text = "󰃠"
                root.brightnessLevel = parsedValue
            } else {
                return
            }
            osdValue.text = state.value + "%"
            osdWindow.osdLevel = parsedValue
            osdCard.opacity = 1
            osdHideTimer.restart()
        } catch (e) { console.warn("[osd] malformed state:", e.message) }
    }
}
