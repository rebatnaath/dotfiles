import QtQuick

// Label + optional sublabel with a right-aligned toggle. Used by the settings
// page for per-panel border/shadow switches.
Item {
    id: toggleRow

    property string label: ""
    property string sublabel: ""
    property bool checked: false
    property bool disabled: false
    signal toggled(bool checked)

    height: 36 * root.uiScale
    width: parent.width
    opacity: disabled ? 0.4 : 1

    Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: toggleRow.label
            font.family: root.fontFamily
            font.pixelSize: 12 * root.uiScale
            color: root.getColor("fg", "#f0dfd8")
        }

        Text {
            visible: toggleRow.sublabel !== ""
            text: toggleRow.sublabel
            font.family: root.fontFamily
            font.pixelSize: 11 * root.uiScale
            color: root.getColor("muted", "#a08d85")
        }
    }

    ToggleSwitch {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: toggleRow.checked
        enabled: !toggleRow.disabled
        onToggled: (c) => toggleRow.toggled(c)
    }
}