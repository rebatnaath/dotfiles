import QtQuick
import Quickshell.Io

// Scrollable settings page: edit the rice-wide visual tokens. Edits the shell
// root's reactive properties for instant feedback, then persists via
// root.saveRiceSettings(). The container decides the height (see callers).
Flickable {
    id: settingsPage
    width: parent.width
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    contentWidth: width
    contentHeight: contentColumn.height

    Column {
        id: contentColumn
        width: settingsPage.width
        spacing: 12 * root.uiScale

        Text {
            width: parent.width
            text: "Rice Settings"
            font.family: root.fontFamily
            font.pixelSize: 13 * root.uiScale
            font.bold: true
            color: root.getColor("accent", "#ffb691")
        }

        // ---- Sway window decorations -------------------------------------

        Text {
            width: parent.width
            text: "Window Decorations"
            font.family: root.fontFamily
            font.pixelSize: 12 * root.uiScale
            font.bold: true
            color: root.getColor("fg", "#f0dfd8")
        }

        SliderRow {
            labelText: "Border"
            maximumValue: 12
            valueUnit: "px"
            value: root.borderWidth
            showHandle: false
            onValuePreviewed: (newValue) => root.borderWidth = newValue
            onValueCommitted: (newValue) => {
                root.borderWidth = newValue
                root.saveRiceSettings()
            }
        }

        SliderRow {
            labelText: "Radius"
            maximumValue: 24
            valueUnit: "px"
            value: root.cornerRadius
            showHandle: false
            onValuePreviewed: (newValue) => root.cornerRadius = newValue
            onValueCommitted: (newValue) => {
                root.cornerRadius = newValue
                root.saveRiceSettings()
            }
        }

        // ---- Effects -------------------------------------------------------

        Text {
            width: parent.width
            text: "Effects"
            font.family: root.fontFamily
            font.pixelSize: 12 * root.uiScale
            font.bold: true
            color: root.getColor("fg", "#f0dfd8")
        }

        SliderRow {
            labelText: "E-Ink Grain"
            minimumValue: 0
            maximumValue: 5
            stepSize: 1
            valueUnit: ""
            value: root.noiseLevel
            valueText: root.noiseLevel === 0 ? "off" : root.noiseLevel + ""
            showHandle: true
            onValuePreviewed: (newValue) => root.noiseLevel = newValue
            onValueCommitted: (newValue) => root.setNoiseLevel(newValue)
        }

                SliderRow {
            labelText: "Night Light Intensity"
            minimumValue: 0
            maximumValue: 5
            stepSize: 1
            valueUnit: ""
            value: root.nightLightIntensity
            valueText: root.nightLightIntensity === 0 ? "off" : root.nightLightIntensity + ""
            showHandle: true
            onValuePreviewed: (v) => root.nightLightIntensity = v
            onValueCommitted: (v) => {
                root.setNightLightIntensity(v)
            }
        }

        // ---- Bar position -------------------------------------------------

        Text {
            width: parent.width
            text: "Bar Position"
            font.family: root.fontFamily
            font.pixelSize: 12 * root.uiScale
            font.bold: true
            color: root.getColor("fg", "#f0dfd8")
        }

        Row {
            width: parent.width
            spacing: 10 * root.uiScale

            PillButton {
                width: (parent.width - 10) / 2
                labelText: "Top"
                isChecked: root.barSide === "top"
                onClicked: {
                    root.barSide = "top"
                    root.saveRiceSettings()
                }
            }

            PillButton {
                width: (parent.width - 10) / 2
                labelText: "Bottom"
                isChecked: root.barSide === "bottom"
                onClicked: {
                    root.barSide = "bottom"
                    root.saveRiceSettings()
                }
            }
        }

        // ---- Bar style ----------------------------------------------------

        Text {
            width: parent.width
            text: "Bar Style"
            font.family: root.fontFamily
            font.pixelSize: 12 * root.uiScale
            font.bold: true
            color: root.getColor("fg", "#f0dfd8")
        }

        Row {
            width: parent.width
            spacing: 10 * root.uiScale

            PillButton {
                width: (parent.width - 10) / 2
                labelText: "Fox"
                isChecked: root.activeBar === "fox"
                onClicked: {
                    root.activeBar = "fox"
                    root.saveRiceSettings()
                }
            }

            PillButton {
                width: (parent.width - 10) / 2
                labelText: "Lonely"
                isChecked: root.activeBar === "lonely"
                onClicked: {
                    root.activeBar = "lonely"
                    root.saveRiceSettings()
                }
            }
        }

        // ---- Global font --------------------------------------------------

        Text {
            width: parent.width
            text: "Font"
            font.family: root.fontFamily
            font.pixelSize: 12 * root.uiScale
            font.bold: true
            color: root.getColor("fg", "#f0dfd8")
        }

        FontPicker {
            width: parent.width
            onChosen: (f) => root.saveRiceSettings()
        }

        Text {
            width: parent.width
        // ---- Panel settings ----------------------------------------------

        Column {
            id: panelSettings
            width: parent.width
            spacing: 12

        // ---- Panel settings ----------------------------------------------

        Text {
            width: parent.width
            text: "Panels"
            font.family: root.fontFamily
            font.pixelSize: 12 * root.uiScale
            font.bold: true
            color: root.getColor("fg", "#f0dfd8")
        }

        Text {
            width: parent.width
            text: "Bar"
            font.family: root.fontFamily
            font.pixelSize: 11 * root.uiScale
            font.bold: true
            color: root.getColor("muted", "#a08d85")
        }

        ToggleRow {
            label: "Border"
            sublabel: "accent outline on the bar"
            checked: root.barBorder
            onToggled: (c) => {
                root.barBorder = c
                root.saveRiceSettings()
            }
        }

        ToggleRow {
            label: "Shadow"
            sublabel: "offset shadow under the bar"
            checked: root.barShadow
            onToggled: (c) => {
                root.barShadow = c
                root.saveRiceSettings()
            }
        }

        ToggleRow {
            label: "Full Width"
            sublabel: "stretch the bar edge-to-edge"
            checked: root.barFullWidth
            onToggled: (c) => {
                root.barFullWidth = c
                root.saveRiceSettings()
            }
        }

        ToggleRow {
            label: "Night Light"
            sublabel: "wlsunset warm filter over the screen"
            checked: root.isNightLightEnabled
            onToggled: (c) => {
                root.toggleNightLight()
            }
        }

        Text {
            width: parent.width
            text: "Quick Menu"
            font.family: root.fontFamily
            font.pixelSize: 11 * root.uiScale
            font.bold: true
            color: root.getColor("muted", "#a08d85")
        }

        ToggleRow {
            label: "Border"
            sublabel: "accent outline on the quick menu"
            checked: root.quickMenuBorder
            onToggled: (c) => {
                root.quickMenuBorder = c
                root.saveRiceSettings()
            }
        }

        ToggleRow {
            label: "Shadow"
            sublabel: "offset shadow on the quick menu"
            checked: root.quickMenuShadow
            onToggled: (c) => {
                root.quickMenuShadow = c
                root.saveRiceSettings()
            }
        }

        Text {
            width: parent.width
            text: "OSD"
            font.family: root.fontFamily
            font.pixelSize: 11 * root.uiScale
            font.bold: true
            color: root.getColor("muted", "#a08d85")
        }

        ToggleRow {
            label: "Border"
            sublabel: "accent outline on the OSD"
            checked: root.osdBorder
            onToggled: (c) => {
                root.osdBorder = c
                root.saveRiceSettings()
            }
        }

        ToggleRow {
            label: "Shadow"
            sublabel: "offset shadow on the OSD"
            checked: root.osdShadow
            onToggled: (c) => {
                root.osdShadow = c
                root.saveRiceSettings()
            }
        }
        }
    }
}