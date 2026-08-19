import QtQuick

// Display-only battery pill: icon reflects charge level/charging state and
// turns red when the battery is low and discharging.
PillButton {
    id: batteryPill

    property int batteryLevel: -1
    property string batteryStatus: "Unknown"

    readonly property bool isLowBattery: batteryLevel >= 0
        && batteryStatus !== "Charging"
        && batteryLevel <= 15

    isActive: true
    isDanger: isLowBattery

    function batteryGlyph() {
        var level = batteryLevel
        if (level < 0) return "󰂑"
        if (batteryStatus === "Charging") {
            if (level < 20) return "󰢜"
            if (level < 30) return "󰂇"
            if (level < 40) return "󰂈"
            if (level < 60) return "󰂉"
            if (level < 80) return "󰂊"
            if (level < 90) return "󰂋"
            return "󰂅"
        }
        if (level < 10) return "󰂎"
        if (level < 20) return "󰁺"
        if (level < 30) return "󰁻"
        if (level < 40) return "󰁼"
        if (level < 50) return "󰁽"
        if (level < 60) return "󰁾"
        if (level < 70) return "󰁿"
        if (level < 80) return "󰂀"
        if (level < 90) return "󰂁"
        if (level < 100) return "󰂂"
        return "󰁹"
    }

    iconText: batteryGlyph()
    labelText: batteryLevel < 0 ? "--" : batteryLevel + "%"
}
