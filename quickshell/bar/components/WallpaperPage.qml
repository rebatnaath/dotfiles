import QtQuick
import "../picker-data.js" as Picker

// Wallpaper page: search + count + reload header over a thumbnail grid.
// Owns its own model so typing in the search box can filter live. Matching is
// done against the file name AND the folder it lives in (e.g. walls/fox/*.jpg
// all match a search for "fox"). Re-emits reloadRequested whenever it becomes
// visible and wallpaperChosen(path) when a tile is clicked, so the parent can
// refresh data and apply the theme.
Column {
    id: wallpaperPageColumn

    readonly property int headerRowHeight: 24
    readonly property int searchRowHeight: 26
    readonly property int grainRowHeight: 26
    readonly property int pageSpacing: 10
    property int wallpaperCount: 0
    property real gridAvailableHeight: 240
    signal reloadRequested()
    signal wallpaperChosen(string path)

    spacing: pageSpacing
    width: parent.width
    anchors.horizontalCenter: parent.horizontalCenter

    onVisibleChanged: {
        if (visible) {
            reloadRequested()
            // Ready to type right away.
            searchInput.forceActiveFocus()
        }
    }

    // ---- Header: count + reload ----
    Row {
        width: parent.width
        height: wallpaperPageColumn.headerRowHeight
        spacing: 8 * root.uiScale

        Text {
            id: wallpaperCountText
            anchors.verticalCenter: parent.verticalCenter
            text: wallpaperPageColumn.wallpaperCount + (wallpaperPageColumn.wallpaperCount === 1 ? " wallpaper" : " wallpapers")
            font.family: root.fontFamily
            font.pixelSize: 12 * root.uiScale
            font.bold: true
            color: root.getColor("accent", "#ffb691")
            width: parent.width - reloadButton.width - 8
            elide: Text.ElideRight
        }

        Rectangle {
            id: reloadButton
            width: 82 * root.uiScale
            height: 22 * root.uiScale
            anchors.verticalCenter: parent.verticalCenter
            color: reloadButtonMouse.hovered
                ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.18)
                : root.withAlpha(root.getColor("accent", "#ffb691"), 0.1)
            border.width: 1 * root.uiScale
            border.color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.3)
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: " Reload"
                font.family: root.fontFamily
                font.pixelSize: 11 * root.uiScale
                color: root.getColor("fg", "#f0dfd8")
            }

            MouseArea {
                id: reloadButtonMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: wallpaperPageColumn.reloadRequested()
            }
        }
    }

    // ---- Search box: filters by file name or containing folder ----
    Rectangle {
        id: searchBox
        width: parent.width
        height: wallpaperPageColumn.searchRowHeight
        radius: 0
        color: root.withAlpha(root.getColor("muted", "#a08d85"), 0.12)
        border.width: 1 * root.uiScale
        border.color: searchInput.activeFocus
            ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.55)
            : root.withAlpha(root.getColor("accent", "#ffb691"), 0.25)

        Text {
            id: searchIcon
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "󰍉"
            font.family: root.fontFamily
            font.pixelSize: 12 * root.uiScale
            color: root.getColor("muted", "#a08d85")
        }

        Text {
            id: searchPlaceholder
            anchors.left: searchIcon.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            visible: searchInput.text === ""
            text: "Search by name or folder…"
            font.family: root.fontFamily
            font.pixelSize: 11 * root.uiScale
            color: root.withAlpha(root.getColor("muted", "#a08d85"), 0.8)
        }

        TextInput {
            id: searchInput
            anchors.left: searchIcon.right
            anchors.leftMargin: 6
            anchors.right: searchClearButton.left
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            font.family: root.fontFamily
            font.pixelSize: 11 * root.uiScale
            color: root.getColor("fg", "#f0dfd8")
            selectByMouse: true
            clip: true
            onTextChanged: wallpaperPageColumn.refresh()
        }

        Text {
            id: searchClearButton
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            // Empty text collapses the slot, so the input keeps full width
            // until there is something to clear.
            text: searchInput.text === "" ? "" : "✕"
            font.family: root.fontFamily
            font.pixelSize: 12 * root.uiScale
            color: root.getColor("muted", "#a08d85")

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    searchInput.text = ""
                    searchInput.focus = true
                }
            }
        }
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

    GridView {
        id: wallpaperGrid
        width: parent.width
        height: Math.min(wallpaperPageColumn.gridAvailableHeight, wallpaperGrid.contentHeight > 0 ? wallpaperGrid.contentHeight : 0)
        // Whole-pixel cells so tile borders land on crisp pixel boundaries
        // (fractional cell sizes render the borders blurry/uneven).
        cellWidth: Math.floor(width / 4)
        cellHeight: Math.floor(cellWidth * 9 / 16) + 6
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: true
        model: wallpaperModel

        delegate: Item {
            width: wallpaperGrid.cellWidth
            height: wallpaperGrid.cellHeight

            Rectangle {
                anchors { fill: parent; margins: 2 }
                color: root.getColor("bg", "#1a120e")
                border.width: model.active ? 2 : 1
                border.color: model.active
                    ? root.getColor("accent", "#ffb691")
                    : root.withAlpha(root.getColor("muted", "#a08d85"), 0.5)
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: 2
                    source: model.thumb
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(180, 100)
                    smooth: true
                    asynchronous: true
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wallpaperPageColumn.wallpaperChosen(model.path)
                }
            }
        }
    }

    // ---- Data + filtering ----
    ListModel { id: wallpaperModel }
    // Full unfiltered list; set by the parent via setWallpapers/setWallpapersFromJson.
    property var allWallpapers: []
    property string activePath: ""

    // Replace the whole list (from picker-data.js or a --data-only reload).
    function setWallpapers(list, active) {
        wallpaperPageColumn.allWallpapers = list || []
        wallpaperPageColumn.activePath = active || ""
        refresh()
    }

    function setWallpapersFromJson(text) {
        try {
            var obj = JSON.parse(text)
            if (!obj || !obj.walls) return
            setWallpapers(obj.walls, obj.active)
        } catch (e) { /* keep the current list on failure */ }
    }

    // Rebuild the model from the full list, applying the search filter via
    // the shared matcher (file name, folder name or relative path).
    function refresh() {
        wallpaperModel.clear()
        var q = searchInput.text.trim()
        var count = 0
        for (var i = 0; i < wallpaperPageColumn.allWallpapers.length; i++) {
            var w = wallpaperPageColumn.allWallpapers[i]
            if (!Picker.matchesQuery(w, q)) continue
            wallpaperModel.append({
                name: w.name,
                path: w.path,
                thumb: w.thumb,
                active: (w.active === true || w.path === wallpaperPageColumn.activePath)
            })
            count++
        }
        wallpaperPageColumn.wallpaperCount = count
    }
}
