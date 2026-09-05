import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import "../components"
import "../picker-data.js" as Picker

// unified settings window with sidebar navigation
FloatingWindow {
    id: settingsWindow
    title: "Settings"
    color: "transparent"

    property int sidebarWidth: 180 * root.uiScale
    property int currentPage: 0
    property int quickshellTab: 0
    readonly property var pages: ["Wallpaper", "Sway", "Quickshell", "Effects", "Font"]

    implicitWidth: sidebarWidth + 420 * root.uiScale
    implicitHeight: 540 * root.uiScale
    visible: root.isSettingsWindowOpen

    onVisibleChanged: {
        if (!visible) root.isSettingsWindowOpen = false
    }

    Process {
        id: wallpaperApplyProc
    }

    // main card
    Rectangle {
        id: mainCard
        anchors.fill: parent
        radius: root.frameRadius
        color: root.getColor("bg", "#1a120e")

        Row {
            anchors.fill: parent
            anchors.margins: 1 * root.uiScale
            spacing: 0

            // ---- Sidebar ----
            Rectangle {
                id: sidebar
                width: settingsWindow.sidebarWidth
                height: parent.height
                color: "transparent"

                Column {
                    anchors.fill: parent
                    anchors.margins: 12 * root.uiScale
                    spacing: 4 * root.uiScale

                    // title
                    Text {
                        width: parent.width
                        text: "Settings"
                        font.family: root.fontFamily
                        font.pixelSize: 14 * root.uiScale
                        font.bold: true
                        color: root.getColor("accent", "#ffb691")
                        height: 36 * root.uiScale
                        verticalAlignment: Text.AlignVCenter
                    }

                    // sidebar items
                    Repeater {
                        model: settingsWindow.pages

                        Rectangle {
                            required property string modelData
                            required property int index
                            width: parent.width
                            height: 34 * root.uiScale
                            radius: 6 * root.uiScale
                            color: settingsWindow.currentPage === index
                                ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.15)
                                : sidebarItemArea.containsMouse
                                    ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.08)
                                    : "transparent"

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 12 * root.uiScale
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    switch (index) {
                                        case 0: return "󰸉 Wallpaper"
                                        case 1: return " Sway"
                                        case 2: return " Quickshell"
                                        case 3: return " Effects"
                                        case 4: return " Font"
                                        default: return modelData
                                    }
                                }
                                font.family: root.fontFamily
                                font.pixelSize: 12 * root.uiScale
                                font.bold: settingsWindow.currentPage === index
                                color: settingsWindow.currentPage === index
                                    ? root.getColor("accent", "#ffb691")
                                    : root.getColor("fg", "#f0dfd8")
                            }

                            MouseArea {
                                id: sidebarItemArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsWindow.currentPage = index
                            }
                                }
                            }
                        }

                // vertical separator between sidebar and content
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1 * root.uiScale
                    color: root.withAlpha(root.getColor("muted", "#a08d85"), 0.2)
                }
            }

            // ---- Content area ----
            Flickable {
                id: contentFlickable
                width: parent.width - settingsWindow.sidebarWidth
                height: parent.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: contentColumn.height

                Column {
                    id: contentColumn
                    anchors.fill: parent
                    anchors.margins: 24 * root.uiScale
                    spacing: 24 * root.uiScale

                    // padding top
                    Item { width: 1; height: 16 * root.uiScale }

                    // ---- Wallpaper page ----
                    SettingsPage {
                        title: "Wallpaper"
                        subtitle: "Choose your desktop background"
                        visible: settingsWindow.currentPage === 0

                        WallpaperPage {
                            id: wallpaperPage
                            width: parent.width
                            gridAvailableHeight: contentFlickable.height - 90 * root.uiScale
                            onWallpaperChosen: (path) => {
                                wallpaperPage.setActive(path)
                                wallpaperApplyProc.command = ["bash", root.homeDir + "/.config/sway/scripts/theme-switch", path]
                                wallpaperApplyProc.running = true
                            }
                            onReloadRequested: wallpaperPage.refresh()
                        }
                    }

                    // ---- Sway page ----
                    SettingsPage {
                        title: "Sway"
                        subtitle: "Window manager border and shape"
                        visible: settingsWindow.currentPage === 1

                        // Card grouping
                        Rectangle {
                            width: parent.width
                            height: swayCard.height + 24 * root.uiScale
                            radius: 8 * root.uiScale
                            color: root.withAlpha(root.getColor("muted", "#a08d85"), 0.06)

                            Column {
                                id: swayCard
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 14 * root.uiScale
                                    rightMargin: 14 * root.uiScale
                                }
                                spacing: 10 * root.uiScale

                                SliderRow {
                                    labelText: "Border Width"
                                    maximumValue: 12
                                    valueUnit: "px"
                                    value: root.borderWidth
                                    showHandle: false
                                    onValuePreviewed: (v) => root.borderWidth = v
                                    onValueCommitted: (v) => {
                                        root.borderWidth = v
                                        root.saveRiceSettings()
                                    }
                                }

                                SliderRow {
                                    labelText: "Corner Radius"
                                    maximumValue: 24
                                    valueUnit: "px"
                                    value: root.cornerRadius
                                    showHandle: false
                                    onValuePreviewed: (v) => root.cornerRadius = v
                                    onValueCommitted: (v) => {
                                        root.cornerRadius = v
                                        root.saveRiceSettings()
                                    }
                                }
                            }
                        }
                    }

                    // ---- Quickshell page ----
                    SettingsPage {
                        title: "Quickshell"
                        subtitle: "Bar, menu, and on-screen display"
                        visible: settingsWindow.currentPage === 2

                        // Tab row
                        Rectangle {
                            width: parent.width
                            height: 30 * root.uiScale
                            radius: 6 * root.uiScale
                            color: root.withAlpha(root.getColor("muted", "#a08d85"), 0.08)

                            Row {
                                anchors.fill: parent
                                anchors.margins: 3 * root.uiScale
                                spacing: 2 * root.uiScale

                                Repeater {
                                    model: ["Bar", "Quick Menu", "OSD"]

                                    Rectangle {
                                        required property string modelData
                                        required property int index
                                        width: (parent.width - 4) / 3
                                        height: parent.height
                                        radius: 4 * root.uiScale
                                        color: settingsWindow.quickshellTab === index
                                            ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.25)
                                            : tabMouse.containsMouse
                                                ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.1)
                                                : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.family: root.fontFamily
                                            font.pixelSize: 11 * root.uiScale
                                            font.bold: settingsWindow.quickshellTab === index
                                            color: settingsWindow.quickshellTab === index
                                                ? root.getColor("accent", "#ffb691")
                                                : root.getColor("fg", "#f0dfd8")
                                        }

                                        MouseArea {
                                            id: tabMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: settingsWindow.quickshellTab = index
                                        }
                                    }
                                }
                            }
                        }

                        // ---- Bar tab ----
                        Column {
                            width: parent.width
                            spacing: 10 * root.uiScale
                            visible: settingsWindow.quickshellTab === 0

                            Rectangle {
                                width: parent.width
                                height: barCardCol.height + 24 * root.uiScale
                                radius: 8 * root.uiScale
                                color: root.withAlpha(root.getColor("muted", "#a08d85"), 0.06)

                                Column {
                                    id: barCardCol
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 14 * root.uiScale
                                        rightMargin: 14 * root.uiScale
                                    }
                                    spacing: 10 * root.uiScale

                                    Text {
                                        width: parent.width
                                        text: "Position"
                                        font.family: root.fontFamily
                                        font.pixelSize: 11 * root.uiScale
                                        font.bold: true
                                        color: root.getColor("muted", "#a08d85")
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

                                    Text {
                                        width: parent.width
                                        text: "Type"
                                        font.family: root.fontFamily
                                        font.pixelSize: 11 * root.uiScale
                                        font.bold: true
                                        color: root.getColor("muted", "#a08d85")
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
                                            labelText: "Cat"
                                            isChecked: root.activeBar === "cat"
                                            onClicked: {
                                                root.activeBar = "cat"
                                                root.saveRiceSettings()
                                            }
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
                                        label: "Status Bar"
                                        sublabel: "show wifi/battery/volume instead of ctrls"
                                        checked: root.foxStatusBar
                                        visible: root.activeBar === "fox"
                                        opacity: root.activeBar === "fox" ? 1 : 0.35
                                        onToggled: (c) => {
                                            root.foxStatusBar = c
                                            root.saveRiceSettings()
                                        }
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

                                    SliderRow {
                                        labelText: "Width"
                                        maximumValue: 12
                                        valueUnit: "px"
                                        value: root.barBorderWidth
                                        showHandle: false
                                        opacity: root.barBorder ? 1 : 0.35
                                        onValuePreviewed: (v) => root.barBorderWidth = v
                                        onValueCommitted: (v) => {
                                            root.barBorderWidth = v
                                            root.saveRiceSettings()
                                        }
                                    }

                                    SliderRow {
                                        labelText: "Corner Radius"
                                        maximumValue: 24
                                        valueUnit: "px"
                                        value: root.barCornerRadius
                                        showHandle: false
                                        onValuePreviewed: (v) => root.barCornerRadius = v
                                        onValueCommitted: (v) => {
                                            root.barCornerRadius = v
                                            root.saveRiceSettings()
                                        }
                                    }

                                    SliderRow {
                                        labelText: "Inner Radius"
                                        minimumValue: 0
                                        maximumValue: 12
                                        stepSize: 1
                                        valueUnit: "px"
                                        value: root.barInnerRadius
                                        showHandle: true
                                        visible: root.activeBar !== "cat"
                                        opacity: root.activeBar !== "cat" ? 1 : 0.35
                                        onValuePreviewed: (v) => root.barInnerRadius = v
                                        onValueCommitted: (v) => {
                                            root.barInnerRadius = v
                                            root.saveRiceSettings()
                                        }
                                    }

                                    ToggleRow {
                                        label: "Shadow"
                                        sublabel: root.barFullWidth ? "disabled in fullwidth" : "offset shadow under the bar"
                                        checked: root.barShadow
                                        disabled: root.barFullWidth
                                        onToggled: (c) => {
                                            root.barShadow = c
                                            root.saveRiceSettings()
                                        }
                                    }
                                }
                            }
                        }

                        // ---- Quick Menu tab ----
                        Column {
                            width: parent.width
                            spacing: 10 * root.uiScale
                            visible: settingsWindow.quickshellTab === 1

                            Rectangle {
                                width: parent.width
                                height: menuCardCol.height + 24 * root.uiScale
                                radius: 8 * root.uiScale
                                color: root.withAlpha(root.getColor("muted", "#a08d85"), 0.06)

                                Column {
                                    id: menuCardCol
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 14 * root.uiScale
                                        rightMargin: 14 * root.uiScale
                                    }
                                    spacing: 10 * root.uiScale

                                    ToggleRow {
                                        label: "Border"
                                        sublabel: "accent outline on the quick menu"
                                        checked: root.quickMenuBorder
                                        onToggled: (c) => {
                                            root.quickMenuBorder = c
                                            root.saveRiceSettings()
                                        }
                                    }

                                    SliderRow {
                                        labelText: "Width"
                                        maximumValue: 12
                                        valueUnit: "px"
                                        value: root.quickMenuBorderWidth
                                        showHandle: false
                                        opacity: root.quickMenuBorder ? 1 : 0.35
                                        onValuePreviewed: (v) => root.quickMenuBorderWidth = v
                                        onValueCommitted: (v) => {
                                            root.quickMenuBorderWidth = v
                                            root.saveRiceSettings()
                                        }
                                    }

                                    SliderRow {
                                        labelText: "Corner Radius"
                                        maximumValue: 24
                                        valueUnit: "px"
                                        value: root.quickMenuCornerRadius
                                        showHandle: false
                                        onValuePreviewed: (v) => root.quickMenuCornerRadius = v
                                        onValueCommitted: (v) => {
                                            root.quickMenuCornerRadius = v
                                            root.saveRiceSettings()
                                        }
                                    }

                                    SliderRow {
                                        labelText: "Inner Radius"
                                        minimumValue: 0
                                        maximumValue: 12
                                        stepSize: 1
                                        valueUnit: "px"
                                        value: root.quickMenuInnerRadius
                                        showHandle: true
                                        onValuePreviewed: (v) => root.quickMenuInnerRadius = v
                                        onValueCommitted: (v) => {
                                            root.quickMenuInnerRadius = v
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
                                }
                            }
                        }

                        // ---- OSD tab ----
                        Column {
                            width: parent.width
                            spacing: 10 * root.uiScale
                            visible: settingsWindow.quickshellTab === 2

                            Rectangle {
                                width: parent.width
                                height: osdCardCol.height + 24 * root.uiScale
                                radius: 8 * root.uiScale
                                color: root.withAlpha(root.getColor("muted", "#a08d85"), 0.06)

                                Column {
                                    id: osdCardCol
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 14 * root.uiScale
                                        rightMargin: 14 * root.uiScale
                                    }
                                    spacing: 10 * root.uiScale

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

                                    SliderRow {
                                        labelText: "Corner Radius"
                                        maximumValue: 24
                                        valueUnit: "px"
                                        value: root.osdCornerRadius
                                        showHandle: false
                                        onValuePreviewed: (v) => root.osdCornerRadius = v
                                        onValueCommitted: (v) => {
                                            root.osdCornerRadius = v
                                            root.saveRiceSettings()
                                        }
                                    }

                                    SliderRow {
                                        labelText: "Margin"
                                        maximumValue: 80
                                        valueUnit: "px"
                                        value: root.osdMargin
                                        showHandle: false
                                        onValuePreviewed: (v) => root.osdMargin = v
                                        onValueCommitted: (v) => {
                                            root.osdMargin = v
                                            root.saveRiceSettings()
                                        }
                                    }
                                }
                            }

                            // Position card
                            Rectangle {
                                width: parent.width
                                height: osdPosCol.height + 24 * root.uiScale
                                radius: 8 * root.uiScale
                                color: root.withAlpha(root.getColor("muted", "#a08d85"), 0.06)

                                Column {
                                    id: osdPosCol
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 14 * root.uiScale
                                        rightMargin: 14 * root.uiScale
                                    }
                                    spacing: 10 * root.uiScale

                                    Text {
                                        width: parent.width
                                        text: "Position"
                                        font.family: root.fontFamily
                                        font.pixelSize: 12 * root.uiScale
                                        font.bold: true
                                        color: root.getColor("muted", "#a08d85")
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: 10 * root.uiScale

                                        PillButton {
                                            width: (parent.width - 24) / 4
                                            labelText: "Top Left"
                                            isChecked: root.osdPosition === "top-left"
                                            onClicked: {
                                                root.osdPosition = "top-left"
                                                root.saveRiceSettings()
                                            }
                                        }

                                        PillButton {
                                            width: (parent.width - 24) / 4
                                            labelText: "Top Right"
                                            isChecked: root.osdPosition === "top-right"
                                            onClicked: {
                                                root.osdPosition = "top-right"
                                                root.saveRiceSettings()
                                            }
                                        }

                                        PillButton {
                                            width: (parent.width - 24) / 4
                                            labelText: "Bottom Left"
                                            isChecked: root.osdPosition === "bottom-left"
                                            onClicked: {
                                                root.osdPosition = "bottom-left"
                                                root.saveRiceSettings()
                                            }
                                        }

                                        PillButton {
                                            width: (parent.width - 24) / 4
                                            labelText: "Bottom Right"
                                            isChecked: root.osdPosition === "bottom-right"
                                            onClicked: {
                                                root.osdPosition = "bottom-right"
                                                root.saveRiceSettings()
                                            }
                                        }
                                    }
                                }
                            }

                            // Notification card
                            Rectangle {
                                width: parent.width
                                height: notifCardCol.height + 24 * root.uiScale
                                radius: 8 * root.uiScale
                                color: root.withAlpha(root.getColor("muted", "#a08d85"), 0.06)

                                Column {
                                    id: notifCardCol
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 14 * root.uiScale
                                        rightMargin: 14 * root.uiScale
                                    }
                                    spacing: 10 * root.uiScale

                                    Text {
                                        width: parent.width
                                        text: "Notifications"
                                        font.family: root.fontFamily
                                        font.pixelSize: 12 * root.uiScale
                                        font.bold: true
                                        color: root.getColor("muted", "#a08d85")
                                    }

                                    ToggleRow {
                                        label: "Border"
                                        sublabel: "accent outline on notifications"
                                        checked: root.notificationBorder
                                        onToggled: (c) => {
                                            root.notificationBorder = c
                                            root.saveRiceSettings()
                                        }
                                    }

                                    ToggleRow {
                                        label: "Shadow"
                                        sublabel: "offset shadow on notifications"
                                        checked: root.notificationShadow
                                        onToggled: (c) => {
                                            root.notificationShadow = c
                                            root.saveRiceSettings()
                                        }
                                    }

                                    SliderRow {
                                        labelText: "Corner Radius"
                                        maximumValue: 24
                                        valueUnit: "px"
                                        value: root.notificationCornerRadius
                                        showHandle: false
                                        onValuePreviewed: (v) => root.notificationCornerRadius = v
                                        onValueCommitted: (v) => {
                                            root.notificationCornerRadius = v
                                            root.saveRiceSettings()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ---- Effects page ----
                    SettingsPage {
                        title: "Effects"
                        subtitle: "Visual effects and display"
                        visible: settingsWindow.currentPage === 3

                        Rectangle {
                            width: parent.width
                            height: effectsCard.height + 24 * root.uiScale
                            radius: 8 * root.uiScale
                            color: root.withAlpha(root.getColor("muted", "#a08d85"), 0.06)

                            Column {
                                id: effectsCard
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 14 * root.uiScale
                                    rightMargin: 14 * root.uiScale
                                }
                                spacing: 10 * root.uiScale

                                SliderRow {
                                    labelText: "E-Ink Grain"
                                    minimumValue: 0
                                    maximumValue: 5
                                    stepSize: 1
                                    valueUnit: ""
                                    value: root.noiseLevel
                                    valueText: root.noiseLevel === 0 ? "off" : root.noiseLevel + ""
                                    showHandle: true
                                    onValuePreviewed: (v) => root.noiseLevel = v
                                    onValueCommitted: (v) => root.setNoiseLevel(v)
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
                            }
                        }
                    }

                    // ---- Font page ----
                    SettingsPage {
                        title: "Font"
                        subtitle: "System font family"
                        visible: settingsWindow.currentPage === 4

                        FontPicker {
                            width: parent.width
                            onChosen: root.saveRiceSettings()
                        }
                    }

                    // padding bottom
                    Item { width: 1; height: 16 * root.uiScale }
                }
            }
        }
    }
}
