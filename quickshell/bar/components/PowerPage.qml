import QtQuick

// Power page: lock / logout / power off / restart. Visibility is controlled
// by the caller; actions run through the shared powerMenuProc.
Column {
    id: powerPageColumn
    spacing: 10 * root.uiScale
    width: parent.width
    anchors.horizontalCenter: parent.horizontalCenter

    PowerActionButton {
        iconText: "󰌾"
        labelText: "Lock"
        onClicked: {
            powerMenuProc.command = ["swaylock"]
            powerMenuProc.startDetached()
        }
    }

    PowerActionButton {
        iconText: "󰍃"
        labelText: "Logout"
        onClicked: {
            powerMenuProc.command = ["swaymsg", "exit"]
            powerMenuProc.startDetached()
        }
    }

    PowerActionButton {
        iconText: "󰐥"
        labelText: "Power Off"
        onClicked: {
            powerMenuProc.command = ["systemctl", "poweroff"]
            powerMenuProc.startDetached()
        }
    }

    PowerActionButton {
        iconText: "󰜎"
        labelText: "Restart"
        onClicked: {
            powerMenuProc.command = ["systemctl", "reboot"]
            powerMenuProc.startDetached()
        }
    }
}
