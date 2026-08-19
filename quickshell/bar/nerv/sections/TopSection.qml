import Quickshell
import Quickshell.I3
import QtQuick

// The nerv bar's workspace section, matching the NERV-bar mockup: a horizontal
// row of angel items, each an icon square + uppercase name. A full-height red
// separator sits after every item except the last. The active workspace is a
// white chip with black text.
Rectangle {
    id: workspaceBox
    height: parent ? parent.height : 60 * root.uiScale
    width: workspaceRow.implicitWidth
    color: "transparent"

    // The ten Angels from Neon Genesis Evangelion, starting from the First
    // Angel, one per workspace 1..10; anything above falls back to the number.
    readonly property var angelNames: ["ADAM", "LILITH", "SACHIEL", "SHAMSHEL", "RAMIEL", "GAGHIEL", "ISRAFEL", "SANDALPHON", "MATRIEL", "SAHAQUIEL"]

    function angelName(workspaceId) {
        if (workspaceId >= 1 && workspaceId <= angelNames.length)
            return angelNames[workspaceId - 1]
        return workspaceId.toString()
    }

    // Lowercase file stem used for the angel icon in ../assets (e.g. workspace 3
    // -> "sachiel"), mapped to "<stem>-active.png" / "<stem>-inactive.png" by
    // the delegate.
    function angelId(workspaceId) {
        if (workspaceId >= 1 && workspaceId <= angelNames.length)
            return angelNames[workspaceId - 1].toLowerCase()
        return "w" + workspaceId
    }

    // True when the workspace at the given model index is active. Used to skip
    // drawing a separator next to the active item so its own border stands
    // alone instead of doubling up with the adjacent separator.
    function workspaceIsActive(index) {
        var it = workspaceModel.get(index)
        return it ? it.active : false
    }

    Row {
        id: workspaceRow
        spacing: 0

        // The I3 model only holds workspaces that are focused or contain
        // windows, so this list is dynamic: a workspace only appears once it
        // has a window (or is the active one).
        Repeater {
            id: workspaceRepeater
            model: workspaceModel

            delegate: Item {
                required property var modelData
                required property int index
                readonly property int workspaceId: modelData.id
                readonly property bool workspaceActive: modelData.active
                height: workspaceBox.height
                // Cell width keeps a 120px minimum so short names stay square,
                // but grows to fit the name (the longest, SANDALPHON on workspace
                // 8, gets the most extra room instead of clipping).
                width: Math.max(120 * root.uiScale, 48 * root.uiScale + workspaceLabel.implicitWidth)

                // Inner white container, only filled for the active workspace.
                // Red border frame sits on top of it, around the whole item.
                Rectangle {
                    id: activePanel
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                        margins: 3 * root.uiScale
                    }
                    color: workspaceActive ? "#ffffff" : "transparent"
                }

                Row {
                    id: angelRow
                    anchors.centerIn: parent
                    spacing: 6 * root.uiScale
                    padding: 10 * root.uiScale

                    // Active + inactive angel icons kept loaded at all times; only visibility
                    // flips on focus change, so switching workspaces never waits on
                    // a PNG decode. async makes decoding off the UI thread too.
                    Image {
                        id: angelIconActive
                        width: 22 * root.uiScale
                        height: 22 * root.uiScale
                        anchors.verticalCenter: parent.verticalCenter
                        source: "../assets/" + workspaceBox.angelId(workspaceId) + "-active.png"
                        sourceSize: Qt.size(44, 44)
                        asynchronous: true
                        cache: true
                        smooth: true
                        fillMode: Image.PreserveAspectFit
                        visible: workspaceActive
                    }

                    Image {
                        id: angelIconInactive
                        width: 22 * root.uiScale
                        height: 22 * root.uiScale
                        anchors.verticalCenter: parent.verticalCenter
                        source: "../assets/" + workspaceBox.angelId(workspaceId) + "-inactive.png"
                        sourceSize: Qt.size(44, 44)
                        asynchronous: true
                        cache: true
                        smooth: true
                        fillMode: Image.PreserveAspectFit
                        visible: !workspaceActive
                    }

                    Text {
                        id: workspaceLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: workspaceBox.angelName(workspaceId)
                        font.family: root.fontFamily
                        font.pixelSize: 13 * root.uiScale
                        font.bold: true
                        font.letterSpacing: 1 * root.uiScale
                        color: workspaceActive ? "#000000" : "#ffffff"
                    }
                }

                // Red border frame around the whole active item.
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: workspaceActive ? 3 * root.uiScale : 0
                    border.color: "#9D0A12"
                    visible: workspaceActive
                }

                // Click target covering the whole angel item.
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: I3.dispatch("workspace " + workspaceId)
                }

                // Full-height red separator after each item except the last, and
                // skipped next to the active item so its own border stands alone
                // at 3px instead of stacking with an adjacent separator.
                Rectangle {
                    width: 3 * root.uiScale
                    height: parent.height
                    anchors.right: parent.right
                    color: "#9D0A12"
                    visible: index < workspaceRepeater.count - 1
                        && !workspaceActive
                        && !workspaceBox.workspaceIsActive(index + 1)
                }
            }
        }
    }
}
