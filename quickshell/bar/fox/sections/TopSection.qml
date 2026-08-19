import Quickshell
import Quickshell.I3
import QtQuick

Rectangle {
    id: workspaceBox
    height: 36
    width: workspaceRow.implicitWidth + 12
    color: "transparent"

    // Word labels for workspaces 1..10; anything above falls back to the
    // number itself.
    readonly property var workspaceWords: ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]

    function workspaceWord(workspaceId) {
        if (workspaceId >= 1 && workspaceId <= workspaceWords.length)
            return workspaceWords[workspaceId - 1]
        return workspaceId.toString()
    }

    Row {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: 8

        // The I3 model only holds workspaces that are focused or contain
        // windows, so this list is dynamic: a workspace only appears once it
        // has a window (or is the active one). The active workspace gets a
        // background colour chip instead of coloured text.
        Repeater {
            model: workspaceModel

            delegate: Rectangle {
                required property var modelData
                readonly property int workspaceId: modelData.id
                height: 22
                width: workspaceLabel.implicitWidth + 10
                color: modelData.active
                    ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.3)
                    : "transparent"

                Text {
                    id: workspaceLabel
                    anchors.centerIn: parent
                    text: workspaceBox.workspaceWord(workspaceId)
                    font.family: root.fontFamily
                    font.pixelSize: 14 * root.uiScale
                    font.bold: modelData.active
                    color: root.getColor("fg", "#f0dfd8")
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: I3.dispatch("workspace " + workspaceId)
                }
            }
        }
    }
}
