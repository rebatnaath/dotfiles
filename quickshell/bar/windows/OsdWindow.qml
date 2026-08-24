import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import "../components"

// On-screen display: flashes the volume/brightness level bottom-right, right
// edge aligned with a tiled window's edge (sway outer gap), whenever
// sway/scripts/osd writes the state file, then fades out. Pushes the value
// into the bar's shared state so the bar + quick menu update instantly.
PanelWindow {
    id: osdWindow
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    // Pop up in the top-right corner (below the bar) when the bar sits on
    // top, when the bar is full-width, or in nerv/lain mode; bottom-right
    // otherwise.
    readonly property bool atTop: (root.activeBar === "nerv" || root.activeBar === "lain"
        || root.barSide === "top" || root.barFullWidth)
    anchors {
        top: atTop
        bottom: !atTop
        right: true
    }
    margins {
        top: atTop ? (root.activeBar === "nerv" ? 36 * root.uiScale
            : (root.activeBar === "lain" ? 42 * root.uiScale
            : (root.barFullWidth ? 62 * root.uiScale : 9 * root.uiScale))) : 0
        bottom: atTop ? 0 : 9 * root.uiScale
        right: (root.activeBar === "nerv" ? (root.windowGap + 8) : root.windowGap) * root.uiScale
    }
    implicitWidth: osdCard.implicitWidth
    implicitHeight: osdCard.implicitHeight + 8
    // lain has its own OSD (lain/LainOsd.qml)
    visible: osdCard.opacity > 0 && root.activeBar !== "lain"

    FileView {
        id: osdStateFile
        path: "/home/oryza/.cache/quickshell-osd.json"
        watchChanges: true
        // onFileChanged only fires the watcher; reload() and read the fresh
        // content in onTextChanged.
        onFileChanged: osdStateFile.reload()
        onTextChanged: osdWindow.handleOsdState()
    }

    // Same hard offset shadow as the bar (box-shadow: 8px 8px 0 #000).
    RectangularShadow {
        anchors.fill: osdCard
        radius: 0
        color: "#000000"
        blur: 0
        spread: 0
        offset: Qt.vector2d(8, 8)
        visible: root.osdShadow && root.activeBar !== "nerv"
    }

    Rectangle {
        id: osdCard
        // Start hidden (QML defaults opacity to 1) so the card doesn't sit
        // visible with stale text until the first real keybind.
        opacity: 0
        height: 46 * root.uiScale
        implicitHeight: 46
        // Anchored 8px off the bottom so the shadow below has room; fills the
        // window width so the right edge aligns with a tiled window's edge.
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

            // Level track + fill, same styling as the quick menu volume
            // slider: muted track, accent fill, rounded.
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
                // Fixed width wide enough for "100%" so the card never resizes
                // (and the number never shifts) as the digit count changes.
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

    // Exposed so the notification popup can mirror this exact width.
    readonly property real cardWidth: osdCard.implicitWidth
    property real osdLevel: 0
    // Skip the preload read at startup and any read identical to what we
    // already handled (so bar restarts don't flash the OSD for stale values).
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
            if (state.type === "volume") {
                osdIcon.text = state.state === "muted" ? "ﱝ" : ""
                root.isVolumeMuted = state.state === "muted"
                root.volume = parseInt(state.value)
            } else if (state.type === "brightness") {
                osdIcon.text = "󰃠"
                root.brightnessLevel = parseInt(state.value)
            } else {
                return
            }
            osdValue.text = state.value + "%"
            osdWindow.osdLevel = parseInt(state.value)
            osdCard.opacity = 1
            osdHideTimer.restart()
        } catch (e) { /* ignore malformed state */ }
    }
}
