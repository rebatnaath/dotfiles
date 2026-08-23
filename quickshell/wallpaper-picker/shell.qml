import Quickshell
import Quickshell.Io
import QtQuick
// Shared palette / wallpaper data / components are symlinked from bar/
// (quickshell rejects imports outside the config root, hence the links).
import "colors.js" as Colors
import "picker-data.js" as Picker

ShellRoot {
    id: root

    function getColor(key, fallback) {
        return (typeof Colors.COLORS !== "undefined" && Colors.COLORS[key])
            ? Colors.COLORS[key] : fallback
    }

    function withAlpha(colorHex, alpha) {
        var r = parseInt(colorHex.substring(1, 3), 16)
        var g = parseInt(colorHex.substring(3, 5), 16)
        var b = parseInt(colorHex.substring(5, 7), 16)
        return Qt.rgba(r / 255, g / 255, b / 255, alpha)
    }

    function mixHex(baseHex, accentHex, amount) {
        var r1 = parseInt(baseHex.substring(1, 3), 16)
        var g1 = parseInt(baseHex.substring(3, 5), 16)
        var b1 = parseInt(baseHex.substring(5, 7), 16)
        var r2 = parseInt(accentHex.substring(1, 3), 16)
        var g2 = parseInt(accentHex.substring(3, 5), 16)
        var b2 = parseInt(accentHex.substring(5, 7), 16)
        function byteComponent(n) {
            var s = Math.round(n).toString(16)
            return s.length < 2 ? "0" + s : s
        }
        return "#" + byteComponent(r1 + (r2 - r1) * amount)
            + byteComponent(g1 + (g2 - g1) * amount)
            + byteComponent(b1 + (b2 - b1) * amount)
    }

    readonly property string background: getColor("bg", "#1a120e")
    readonly property string foreground: getColor("fg", "#f0dfd8")
    readonly property string accent: getColor("accent", "#ffb691")
    readonly property string muted: getColor("muted", "#a08d85")

    // ---- Rice settings (mirrors the bar's quick-menu settings page) ----
    property int borderWidth: 4
    readonly property bool borderEnabled: borderWidth > 0
    property int cornerRadius: 0
    property string barSide: "bottom"
    property string fontFamily: "GeistMono NFM"
    property bool barBorder: true
    property bool barShadow: true
    property bool quickMenuBorder: true
    property bool quickMenuShadow: true
    property bool osdBorder: true
    property bool osdShadow: true
    property bool barFullWidth: false
    property string activeBar: "fox"
    property bool nightLight: false
    property int nightLightIntensity: 3
    property int noiseLevel: 0
    property real uiScale: 1

    FileView {
        id: settingsFile
        path: "/home/oryza/.config/quickshell/bar/settings.js"
        preload: true
        blockAllReads: true
        watchChanges: false
    }

    // Load the persisted rice tokens so the tab reflects current state.
    function applyRiceSettings(): void {
        settingsFile.reload()
        var raw = settingsFile.text()
        function boolValue(key, current) {
            var m = new RegExp(key + ':[ \t]*(true|false)').exec(raw)
            return m ? m[1] === "true" : current
        }
        function intValue(key, current) {
            var m = new RegExp(key + ':[ \t]*(\\d+)').exec(raw)
            return m ? parseInt(m[1]) : current
        }
        function stringValue(key, current) {
            var m = new RegExp(key + ':[ \t]*"([^"]*)"').exec(raw)
            return m ? m[1] : current
        }
        borderWidth = intValue("borderWidth", borderWidth)
        cornerRadius = intValue("cornerRadius", cornerRadius)
        barSide = stringValue("barSide", barSide)
        fontFamily = stringValue("fontFamily", fontFamily)
        barBorder = boolValue("barBorder", barBorder)
        barShadow = boolValue("barShadow", barShadow)
        quickMenuBorder = boolValue("quickMenuBorder", quickMenuBorder)
        quickMenuShadow = boolValue("quickMenuShadow", quickMenuShadow)
        osdBorder = boolValue("osdBorder", osdBorder)
        osdShadow = boolValue("osdShadow", osdShadow)
        barFullWidth = boolValue("barFullWidth", barFullWidth)
        activeBar = stringValue("activeBar", activeBar)
        nightLight = boolValue("nightLight", nightLight)
        nightLightIntensity = intValue("nightLightIntensity", nightLightIntensity)
        noiseLevel = intValue("noiseLevel", noiseLevel)
    }

    Process { id: riceSettingsProc }

    Process { id: nightLightProc }

    // Persist the current tokens to sway + disk via the shared bridge script.
    function saveRiceSettings(): void {
        riceSettingsProc.command = ["bash", "/home/oryza/.config/sway/scripts/rice-settings-apply",
            borderWidth + "", cornerRadius + "", barSide, fontFamily,
            barBorder + "", barShadow + "", quickMenuBorder + "", quickMenuShadow + "",
            osdBorder + "", osdShadow + "", barFullWidth + "", activeBar,
            nightLight + "", noiseLevel + "", nightLightIntensity + ""]
        riceSettingsProc.startDetached()
    }

    function setNoiseLevel(level) {
        root.noiseLevel = level
        saveRiceSettings()
    }

    function toggleNightLight() {
        root.nightLight = !root.nightLight
    }

    // bar's shared SettingsPage binds to this
    readonly property bool isNightLightEnabled: nightLight

    // Persist + apply a new intensity seamlessly without a full rice save.
    // Debounced so rapid slider input coalesces into a single apply.
    function setNightLightIntensity(v) {
        root.nightLightIntensity = v
        nightLightDebounce.restart()
    }

    Timer {
        id: nightLightDebounce
        interval: 60
        onTriggered: {
            var mode = root.nightLight ? "on" : "off"
            nightLightProc.command = ["/home/oryza/.config/sway/scripts/nightlight-apply", mode, root.nightLightIntensity + ""]
            nightLightProc.startDetached()
        }
    }

    // ---- Active tab (0 = rice settings, 1 = wallpaper picker) ----
    property int currentTab: 0
    onCurrentTabChanged: {
        if (pickerWindow.visible && currentTab === 1) searchField.forceActiveFocus()
    }

    readonly property int columnsPerRow: 4

    ListModel { id: wallpaperModel }

    Process {
        id: themeApplyProc
    }

    function rebuildGrid() {
        wallpaperModel.clear()
        if (typeof Picker.WALLS === "undefined") return
        var query = searchField.text.trim()
        for (var i = 0; i < Picker.WALLS.length; i++) {
            var wallpaper = Picker.WALLS[i]
            // Shared matcher from picker.js: file name, folder name or
            // relative path (so walls/fox/*.jpg all match "fox").
            if (!Picker.matchesQuery(wallpaper, query)) continue
            wallpaperModel.append({
                name: wallpaper.name,
                path: wallpaper.path,
                thumb: wallpaper.thumb,
                active: (typeof Picker.ACTIVE !== "undefined" && wallpaper.path === Picker.ACTIVE)
            })
        }
        wallpaperGrid.currentIndex = (wallpaperGrid.count > 0) ? 0 : -1
    }

    function navigate(rowDelta, columnDelta) {
        if (wallpaperGrid.count < 1) return
        if (wallpaperGrid.currentIndex < 0) { wallpaperGrid.currentIndex = 0; return }
        var currentIndex = wallpaperGrid.currentIndex
        var lastIndex = wallpaperGrid.count - 1
        var currentRow = Math.floor(currentIndex / columnsPerRow)
        var currentColumn = Math.min(columnsPerRow - 1,
            Math.max(0, (currentIndex % columnsPerRow) + columnDelta))
        var nextRow = Math.min(Math.ceil((lastIndex + 1) / columnsPerRow) - 1,
            Math.max(0, currentRow + rowDelta))
        wallpaperGrid.currentIndex = Math.min(lastIndex, nextRow * columnsPerRow + currentColumn)
        wallpaperGrid.positionViewAtIndex(wallpaperGrid.currentIndex, GridView.Center)
    }

    function applySelectedWallpaper() {
        if (wallpaperGrid.currentIndex < 0) return
        if (typeof Picker.THEME_SWITCH === "undefined") return
        var path = wallpaperModel.get(wallpaperGrid.currentIndex).path
        print("WALLPICK APPLY " + path)
        // --fast: swap the wallpaper immediately; the full retheme (matugen +
        // bar restart) runs in the background so the switch feels instant.
        themeApplyProc.command = [Picker.THEME_SWITCH, "--fast", path]
        themeApplyProc.startDetached()
        closePicker()
    }

    function closePicker() {
        pickerWindow.visible = false
        Qt.quit()
    }

    Shortcut { sequence: "Escape"; onActivated: root.closePicker() }

    Component.onCompleted: {
        root.applyRiceSettings()
        root.rebuildGrid()
    }

    FloatingWindow {
        id: pickerWindow
        // A normal OS toplevel so sway treats it as a regular, stackable app
        // window (title bar, move/resize, tile) instead of a fullscreen layer
        // popup that overlays everything.
        title: "Wallpaper Picker"
        color: root.background
        visible: true
        implicitWidth: 800
        implicitHeight: 700
        minimumSize: Qt.size(560, 640)

        // Focus the search field whenever the wallpaper tab is the active one
        // and the window is up, so typing works from the first keystroke.
        onVisibleChanged: {
            if (visible && root.currentTab === 1) searchField.forceActiveFocus()
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            clip: true

            Row {
                id: tabBar
                anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 18; rightMargin: 18; topMargin: 18 }
                height: 42
                spacing: 8

                    Repeater {
                        model: [
                            { label: "Rice Settings", index: 0 },
                            { label: "Wallpapers", index: 1 }
                        ]

                        delegate: Rectangle {
                            width: (tabBar.width - tabBar.spacing) / 2
                            height: tabBar.height
                            color: root.currentTab === modelData.index
                                ? root.withAlpha(root.accent, 0.28)
                                : root.withAlpha(root.muted, 0.12)
                            border.width: 1
                            border.color: root.currentTab === modelData.index
                                ? root.accent : root.muted
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: root.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                                color: root.currentTab === modelData.index
                                    ? root.foreground : root.muted
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentTab = modelData.index
                            }
                        }
                    }
                }

                Item {
                id: contentArea
                anchors { left: parent.left; right: parent.right; top: tabBar.bottom; bottom: parent.bottom; leftMargin: 18; rightMargin: 18; topMargin: 12; bottomMargin: 18 }

                SettingsPage {
                    anchors.fill: parent
                    visible: root.currentTab === 0
                }


                    Column {
                        anchors.fill: parent
                        visible: root.currentTab === 1
                        spacing: 12

                        Rectangle {
                            id: searchContainer
                            width: parent.width
                            height: 44
                            radius: 0
                            color: "transparent"
                            border.width: 1
                            border.color: root.muted

                            TextInput {
                                id: searchField
                                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                                verticalAlignment: TextInput.AlignVCenter
                                color: root.foreground
                                selectionColor: root.accent
                                font.family: root.fontFamily
                                font.pixelSize: 15
                                selectByMouse: true
                                onAccepted: root.applySelectedWallpaper()
                                onTextChanged: root.rebuildGrid()
                                Keys.onReturnPressed: root.applySelectedWallpaper()
                                Keys.onEscapePressed: root.closePicker()
                                Keys.onUpPressed: root.navigate(-1, 0)
                                Keys.onDownPressed: root.navigate(1, 0)
                                Keys.onLeftPressed: root.navigate(0, -1)
                                Keys.onRightPressed: root.navigate(0, 1)
                            }

                            Text {
                                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                                verticalAlignment: Text.AlignVCenter
                                color: root.muted
                                font.family: root.fontFamily
                                font.pixelSize: 15
                                text: "Filter wallpapers\u2026"
                                visible: searchField.text.length === 0
                            }
                        }

                        GridView {
                            id: wallpaperGrid
                            width: parent.width
                            height: parent.height - searchContainer.height
                            cellWidth: width / columnsPerRow
                            cellHeight: Math.floor(cellWidth * 9 / 16) + 12
                            clip: true
                            interactive: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: wallpaperModel
                            currentIndex: -1
                            highlightFollowsCurrentItem: false

                            delegate: Item {
                                width: wallpaperGrid.cellWidth
                                height: wallpaperGrid.cellHeight

                                Rectangle {
                                    anchors { fill: parent; margins: 3 }
                                    radius: 0
                                    color: root.background
                                    border.width: model.active ? 3 : (wallpaperGrid.currentIndex === index ? 2 : 0)
                                    border.color: model.active ? root.accent : root.foreground
                                    clip: true

                                    Image {
                                        anchors { fill: parent; margins: parent.border.width + 3 }
                                        source: model.thumb
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize: Qt.size(480, 270)
                                        smooth: true
                                        asynchronous: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onEntered: wallpaperGrid.currentIndex = index
                                        onClicked: {
                                            wallpaperGrid.currentIndex = index
                                            root.applySelectedWallpaper()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
        }
    }
}