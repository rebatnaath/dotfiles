import QtQuick

// Power page: lock / logout / power off / restart. Visibility is controlled
// by the caller; actions run through the shared powerMenuProc.
Column {
    id: powerPageColumn
    spacing: 10 * root.uiScale
    width: parent.width
    anchors.horizontalCenter: parent.horizontalCenter
    property real itemRadius: 0

    PowerActionButton {
        iconText: "󰌾"
        labelText: "Lock"
        itemRadius: powerPageColumn.itemRadius
        onClicked: {
            powerMenuProc.command = ["swaylock"]
            powerMenuProc.startDetached()
        }
    }

    PowerActionButton {
        iconText: "󰍃"
        labelText: "Logout"
        itemRadius: powerPageColumn.itemRadius
        onClicked: {
            powerMenuProc.command = ["swaymsg", "exit"]
            powerMenuProc.startDetached()
        }
    }

    PowerActionButton {
        iconText: "󰐥"
        labelText: "Power Off"
        itemRadius: powerPageColumn.itemRadius
        onClicked: {
            powerMenuProc.command = ["systemctl", "poweroff"]
            powerMenuProc.startDetached()
        }
    }

    PowerActionButton {
        iconText: "󰜎"
        labelText: "Restart"
        itemRadius: powerPageColumn.itemRadius
        onClicked: {
            powerMenuProc.command = ["systemctl", "reboot"]
            powerMenuProc.startDetached()
        }
    }
}
