import Quickshell
import Quickshell.I3
import QtQuick
import "../components"

// cat bar: accent bar where active workspace blends into bar
BarFace {
    id: catBar

    // bar tint (matches active-window border)
    readonly property color barTint: root.mixHex(root.getColor("bg", "#18130b"), root.getColor("accent", "#ffb691"), 0.25)
    faceColor: barTint
    borderColor: barTint
    readonly property color itemColor: root.getColor("bg", "#18130b")
    // focused workspace/window text color
    readonly property color fgText: root.getColor("fg", "#dee4e1")

    function toggleQuickMenu() { root.isQuickMenuOpen = !root.isQuickMenuOpen }

    // roman numeral for workspace (max 39)
    function toRoman(n) {
        if (n > 39) return n.toString()
        var vals = [[10, "x"], [9, "ix"], [5, "v"], [4, "iv"], [1, "i"]]
        var r = ""
        for (var i = 0; i < vals.length; i++) {
            while (n >= vals[i][0]) { r += vals[i][1]; n -= vals[i][0] }
        }
        return r
    }

    // workspaces (roman numerals)
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        implicitWidth: wsRow.implicitWidth
        color: "transparent"

        Row {
            id: wsRow
            anchors.fill: parent
            spacing: 0

            Repeater {
                model: workspaceModel

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool isFocused: modelData.active
                    // 1:1 square, as tall as the bar (CSS .num).
                    height: parent.height
                    width: parent.height
                    radius: 0
                    topLeftRadius: index === 0 ? root.barCornerRadius * root.uiScale : 0
                    bottomLeftRadius: index === 0 ? root.barCornerRadius * root.uiScale : 0
                    color: isFocused ? catBar.faceColor : catBar.itemColor

                    Text {
                        id: wsLabel
                        anchors.centerIn: parent
                        // roman numeral
                        text: catBar.toRoman(modelData.id)
                        font.family: root.fontFamily
                        font.pixelSize: 11 * root.uiScale
                        font.bold: isFocused
                        color: catBar.fgText
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

    // focused window title
    Text {
        id: titleText
        width: Math.min(implicitWidth, parent.width * 0.4)
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideMiddle
        text: root.windowTitle
        font.family: root.fontFamily
        font.pixelSize: 11 * root.uiScale
        color: catBar.fgText
    }

    // system + time widgets
    Row {
        id: rightWidgets
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0

        Rectangle {
            height: parent.height
            width: batLabel.implicitWidth + 18 * root.uiScale
            color: catBar.itemColor

            Text {
                id: batLabel
                anchors.centerIn: parent
                text: "[bat: " + (root.batteryLevel >= 0 ? root.batteryLevel + "%" : "--") + "]"
                font.family: root.fontFamily
                font.pixelSize: 11 * root.uiScale
                color: catBar.fgText
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: catBar.toggleQuickMenu()
            }
        }

        Rectangle {
            height: parent.height
            width: volLabel.implicitWidth + 18 * root.uiScale
            color: catBar.itemColor

            Text {
                id: volLabel
                anchors.centerIn: parent
                text: "[vol: " + (root.volume >= 0 ? root.volume + "%" : "--") + "]"
                font.family: root.fontFamily
                font.pixelSize: 11 * root.uiScale
                color: catBar.fgText
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: catBar.toggleQuickMenu()
            }
        }

        Rectangle {
            height: parent.height
            width: timeLabel.implicitWidth + 18 * root.uiScale
            color: catBar.itemColor
            topRightRadius: root.barCornerRadius * root.uiScale
            bottomRightRadius: root.barCornerRadius * root.uiScale

            Text {
                id: timeLabel
                anchors.centerIn: parent
                text: "[" + root.timeText + "]"
                font.family: root.fontFamily
                font.pixelSize: 11 * root.uiScale
                color: catBar.fgText
            }

            // status group opens quick menu
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: catBar.toggleQuickMenu()
            }
        }
    }
}
