import Quickshell
import QtQuick

// Small tooltip panel that floats just above the bar. The caller provides the
// content via the default property, positions it with anchoredLeft/Right and
// horizontalMargin, and controls visibility.
PanelWindow {
    id: tipWindow

    property bool anchoredLeft: false
    property bool anchoredRight: false
    property real horizontalMargin: 0
    property int horizontalPadding: 22
    property int verticalPadding: 12
    default property alias tipContent: contentArea.data

    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    anchors { bottom: true; left: anchoredLeft; right: anchoredRight }
    margins {
        bottom: 76
        left: anchoredLeft ? horizontalMargin : 0
        right: anchoredRight ? horizontalMargin : 0
    }
    implicitWidth: contentArea.implicitWidth + horizontalPadding
    implicitHeight: contentArea.implicitHeight + verticalPadding

    Rectangle {
        id: tipCard
        anchors.fill: parent
        color: root.getColor("bg", "#1a120e")
        border.width: 1
        border.color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.8)

        Item {
            id: contentArea
            anchors.centerIn: parent
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
}
