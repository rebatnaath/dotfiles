import QtQuick

// Slider row (icon + track + percent) used for volume and brightness.
// While dragging, valuePreviewed fires continuously so the caller can update
// its value live; valueCommitted fires once on release so the caller applies
// the change to the system.
Row {
    id: sliderRow

    property string iconText: ""
    property string labelText: ""
    property bool iconDimmed: false
    property real value: -1
    property real minimumValue: 0
    property real maximumValue: 100
    // When > 0, the slider snaps the handle/value to whole steps between
    // minimumValue and maximumValue (e.g. 1 for a 5-level discrete control).
    property real stepSize: 0
    property string valueUnit: "%"
    property string valueText: value < 0 ? "--" : Math.round(value) + valueUnit
    property bool showHandle: true
    property bool isDragging: false
    property real trackRadius: 5 * root.uiScale
    signal valuePreviewed(real newValue)
    signal valueCommitted(real newValue)

    spacing: 12 * root.uiScale
    width: parent.width
    anchors.horizontalCenter: parent.horizontalCenter

    Text {
        id: labelItem
        text: sliderRow.labelText.length > 0 ? sliderRow.labelText : sliderRow.iconText
        font.family: root.fontFamily
        font.pixelSize: sliderRow.labelText.length > 0 ? 12 * root.uiScale : 20 * root.uiScale
        // Size to the label content so a wider label (e.g. "E-Ink Grain")
        // doesn't spill underneath the track that follows it.
        width: sliderRow.labelText.length > 0
            ? Math.max(56 * root.uiScale, implicitWidth + 8 * root.uiScale) : 26 * root.uiScale
        horizontalAlignment: sliderRow.labelText.length > 0 ? Text.AlignLeft : Text.AlignHCenter
        color: sliderRow.iconDimmed
            ? root.withAlpha(root.getColor("muted", "#a08d85"), 0.85)
            : root.getColor("fg", "#f0dfd8")
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
        id: track
        width: parent.width - labelItem.width - valueLabel.width - sliderRow.spacing * 2
        height: 12 * root.uiScale
        radius: sliderRow.trackRadius
        color: root.withAlpha(root.getColor("muted", "#a08d85"), 0.22)
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            id: fill
            width: parent.width * (sliderRow.value < sliderRow.minimumValue ? 0
                : (sliderRow.value - sliderRow.minimumValue) / (sliderRow.maximumValue - sliderRow.minimumValue))
            height: parent.height
            radius: sliderRow.trackRadius
            color: trackMouse.hovered
                ? root.mixHex(root.getColor("accent", "#ffb691"), "#ffffff", 0.2)
                : root.getColor("accent", "#ffb691")
            Behavior on width {
                enabled: !sliderRow.isDragging
                NumberAnimation { duration: 100 }
            }
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        // Grab handle shown while hovering/dragging
        Rectangle {
            width: 14 * root.uiScale
            height: 14 * root.uiScale
            radius: 7
            x: Math.max(0, fill.width - width / 2)
            y: (track.height - height) / 2
            color: root.getColor("fg", "#f0dfd8")
            border.width: 2 * root.uiScale
            border.color: root.getColor("accent", "#ffb691")
            visible: sliderRow.showHandle && (trackMouse.hovered || sliderRow.isDragging)
        }

        MouseArea {
            id: trackMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            function percentageAt(mouseX) {
                var norm = mouseX / track.width
                var span = sliderRow.maximumValue - sliderRow.minimumValue
                var v = sliderRow.minimumValue + Math.max(0, Math.min(1, norm)) * span
                if (sliderRow.stepSize > 0) {
                    v = sliderRow.minimumValue + Math.round((v - sliderRow.minimumValue) / sliderRow.stepSize) * sliderRow.stepSize
                    v = Math.max(sliderRow.minimumValue, Math.min(sliderRow.maximumValue, v))
                }
                return v
            }

            onPressed: (mouse) => {
                sliderRow.isDragging = true
                sliderRow.valuePreviewed(percentageAt(mouse.x))
            }
            onPositionChanged: (mouse) => {
                if (pressed) sliderRow.valuePreviewed(percentageAt(mouse.x))
            }
            onReleased: (mouse) => {
                sliderRow.isDragging = false
                sliderRow.valueCommitted(percentageAt(mouse.x))
            }
        }
    }

    Text {
        id: valueLabel
        text: sliderRow.valueText
        font.family: root.fontFamily
        font.pixelSize: 11 * root.uiScale
        color: root.getColor("muted", "#a08d85")
        width: 46 * root.uiScale
        horizontalAlignment: Text.AlignRight
        anchors.verticalCenter: parent.verticalCenter
    }
}
