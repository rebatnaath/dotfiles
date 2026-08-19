import QtQuick

// Small on/off switch (track + thumb), styled to match the bar accents.
Rectangle {
    id: switchControl

    property bool checked: false
    signal toggled(bool checked)

    width: 40 * root.uiScale
    height: 22 * root.uiScale
    radius: 11
    color: checked
        ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.55)
        : root.withAlpha(root.getColor("muted", "#a08d85"), 0.25)
    Behavior on color { ColorAnimation { duration: 120 } }

    Rectangle {
        id: thumb
        width: 16 * root.uiScale
        height: 16 * root.uiScale
        radius: 8
        x: switchControl.checked ? switchControl.width - thumb.width - 3 : 3
        y: (switchControl.height - thumb.height) / 2
        color: root.getColor("fg", "#f0dfd8")
        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: switchMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: switchControl.toggled(!switchControl.checked)
    }
}