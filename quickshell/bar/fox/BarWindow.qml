import Quickshell
import QtQuick
import "../components"
import "sections"

// The classic fox bar: a rounded face with the clock pinned left, workspace
// labels centered, and a "ctrls" system group on the right. All the floating/
// shadow/border chrome lives in the shared BarFace; this only supplies the
// three sections' layout.
BarFace {
    id: bar

    MiddleSection {
        anchors.left: parent.left
        anchors.leftMargin: 12 * root.uiScale
        anchors.verticalCenter: parent.verticalCenter
    }

    TopSection {
        anchors.centerIn: parent
    }

    BottomSection {
        anchors.right: parent.right
        anchors.rightMargin: 12 * root.uiScale
        anchors.verticalCenter: parent.verticalCenter
    }
}