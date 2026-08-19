import Quickshell
import Quickshell.I3
import QtQuick
import "../components"

// The "lonely" bar: a single-colour accent bar where the background and the
// active workspace share one matugen colour (so the active workspace blends
// invisibly into the bar), while inactive workspaces get a darkened matugen
// chip. Workspaces (roman numerals) sit left, the focused window title centered,
// the time right. The floating/shadow/border chrome comes from the shared
// BarFace; the border is a solid face-colour ring.
BarFace {
    id: lonelyBar
    // Time widget toggles between HH:MM and the full date on click.
    property bool showDate: false

    // The bar background and its border share one matugen colour (surface
    // variant), opaque so it shows the same regardless of the wallpaper behind.
    faceColor: root.getColor("muted", "#9b8f80")
    borderColor: root.getColor("muted", "#9b8f80")
    readonly property color itemColor: root.getColor("bg", "#18130b")
    // Focused-workspace + focused-window text share the lightest matugen tone
    // so they read clearly against the outline-coloured background/border.
    readonly property color fgText: root.getColor("fg", "#dee4e1")

    // Sway destroys empty workspaces, so list indices map to 1..N roman labels.
    function toRoman(n) {
        var vals = [[10, "x"], [9, "ix"], [5, "v"], [4, "iv"], [1, "i"]]
        var r = ""
        for (var i = 0; i < vals.length; i++) {
            while (n >= vals[i][0]) { r += vals[i][1]; n -= vals[i][0] }
        }
        return r
    }

    // Workspaces (roman numerals) on the left. Their background extends to the
    // face edges (under the border ring, which is drawn last on top).
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        implicitWidth: wsRow.implicitWidth
        color: "transparent"
        radius: root.frameRadius
        clip: true

        Row {
            id: wsRow
            anchors.fill: parent
            spacing: 0

            Repeater {
                model: workspaceModel

                delegate: Rectangle {
                    required property var modelData
                    readonly property bool isFocused: modelData.active
                    // 1:1 square, as tall as the bar (CSS .num).
                    height: parent.height
                    width: parent.height
                    color: isFocused ? lonelyBar.faceColor : lonelyBar.itemColor

                    Text {
                        id: wsLabel
                        anchors.centerIn: parent
                        // Workspace numbers map to their actual roman numeral.
                        text: lonelyBar.toRoman(modelData.id)
                        font.family: root.fontFamily
                        font.pixelSize: 11 * root.uiScale
                        font.bold: isFocused
                        color: lonelyBar.fgText
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: I3.dispatch("workspace " + modelData.id)
                    }
                }
            }
        }
    }

    // Focused window title, centered.
    Text {
        id: titleText
        width: Math.min(implicitWidth, parent.width * 0.4)
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideMiddle
        text: root.windowTitle
        font.family: root.fontFamily
        font.pixelSize: 11 * root.uiScale
        color: lonelyBar.fgText
    }

    // System + time widgets on the right: full-height blocks flush against the
    // top/bottom/right borders, no outer margins (CSS .status-list). Each shows
    // [bat %], [vol %], [HH:MM]; the time toggles to the date.
    Row {
        id: rightWidgets
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0

        Rectangle {
            height: parent.height
            width: batLabel.implicitWidth + 18 * root.uiScale
            color: lonelyBar.itemColor

            Text {
                id: batLabel
                anchors.centerIn: parent
                text: "[bat: " + (root.batteryLevel >= 0 ? root.batteryLevel + "%" : "--") + "]"
                font.family: root.fontFamily
                font.pixelSize: 11 * root.uiScale
                color: lonelyBar.fgText
            }
        }

        Rectangle {
            height: parent.height
            width: volLabel.implicitWidth + 18 * root.uiScale
            color: lonelyBar.itemColor

            Text {
                id: volLabel
                anchors.centerIn: parent
                text: "[vol: " + (root.volume >= 0 ? root.volume + "%" : "--") + "]"
                font.family: root.fontFamily
                font.pixelSize: 11 * root.uiScale
                color: lonelyBar.fgText
            }
        }

        Rectangle {
            height: parent.height
            width: timeLabel.implicitWidth + 18 * root.uiScale
            color: lonelyBar.itemColor

            Text {
                id: timeLabel
                anchors.centerIn: parent
                text: "[" + (lonelyBar.showDate ? root.dateText : root.timeText) + "]"
                font.family: root.fontFamily
                font.pixelSize: 11 * root.uiScale
                color: lonelyBar.fgText
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: lonelyBar.showDate = !lonelyBar.showDate
            }
        }
    }
}