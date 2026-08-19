import QtQuick

// The right-hand label, a NERV command-center reference (the MAGI system, the
// three supercomputers that run NERV): a full-height red left border, then a
// column of kanji over "MAGI SYSTEM", right-aligned, all in red. Clicking it
// opens the quick menu / control center.
Item {
    id: zone
    height: parent ? parent.height : 60 * root.uiScale
    width: zoneColumn.width + 40 * root.uiScale

    Rectangle {
        width: 3 * root.uiScale
        height: parent.height
        anchors.left: parent.left
        color: "#9D0A12"
    }

    Column {
        id: zoneColumn
        anchors.right: parent.right
        anchors.rightMargin: 20 * root.uiScale
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            anchors.right: parent.right
            text: "マギ"
            font.family: root.fontFamily
            font.pixelSize: 18 * root.uiScale
            font.bold: true
            font.letterSpacing: 4 * root.uiScale
            color: "#F3B2B0"
        }

        Text {
            anchors.right: parent.right
            text: "MAGI SYSTEM"
            font.family: root.fontFamily
            font.pixelSize: 12 * root.uiScale
            font.bold: true
            font.letterSpacing: 1.5 * root.uiScale
            color: "#F3B2B0"
        }
    }

    // Click opens the quick menu / control center.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.isQuickMenuOpen = true
    }
}