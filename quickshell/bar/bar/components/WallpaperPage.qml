import QtQuick
import "../picker-data.js" as Picker

// wallpaper page (search + thumbnail grid)
Column {
    id: wallpaperPageColumn

    readonly property int headerRowHeight: 24 * root.uiScale
    readonly property int searchRowHeight: 26 * root.uiScale
    readonly property int pageSpacing: 10 * root.uiScale
    property int wallpaperCount: 0
    property real gridAvailableHeight: 240 * root.uiScale
    property int activeIndex: -1
    signal reloadRequested()
    signal wallpaperChosen(string path)

    spacing: pageSpacing
    width: parent.width
    anchors.horizontalCenter: parent.horizontalCenter

    onVisibleChanged: {
        if (visible) {
            reloadRequested()
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
                text: " Reload"
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

    // ---- Search box ----
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

    GridView {
        id: wallpaperGrid
        width: parent.width
        height: Math.max(60, Math.min(wallpaperPageColumn.gridAvailableHeight, wallpaperGrid.contentHeight > 0 ? wallpaperGrid.contentHeight : 0))
        cellWidth: Math.floor(width / 5)
        cellHeight: Math.floor(cellWidth * 9 / 16) + 6 * root.uiScale
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: true
        model: wallpaperModel

        delegate: Item {
            id: delegateRoot
            width: wallpaperGrid.cellWidth
            height: wallpaperGrid.cellHeight

            Rectangle {
                anchors { fill: parent; margins: 2 }
                color: root.getColor("bg", "#1a120e")
                border.width: model.active ? 3 : 1
                border.color: model.active
                    ? root.getColor("accent", "#ffb691")
                    : root.withAlpha(root.getColor("muted", "#a08d85"), 0.5)
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: 2
                    source: model.thumb
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(180 * root.uiScale, 100 * root.uiScale)
                    smooth: true
                    asynchronous: true
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        wallpaperPageColumn.activeIndex = index
                        wallpaperPageColumn.wallpaperChosen(model.path)
                    }
                }
            }
        }
    }

    // ---- Data + filtering ----
    ListModel { id: wallpaperModel }
    property var allWallpapers: []
    property string activeWallpaperPath: ""

    Component.onCompleted: {
        allWallpapers = Picker.WALLS || []
        activeWallpaperPath = Picker.ACTIVE || ""
        refresh()
    }

    function setWallpapers(list, active) {
        allWallpapers = list || []
        activeWallpaperPath = active || ""
        refresh()
    }

    function setActive(path) {
        activeWallpaperPath = path
        for (var i = 0; i < wallpaperModel.count; i++) {
            wallpaperModel.setProperty(i, "active", wallpaperModel.get(i).path === path)
        }
    }

    function refresh() {
        wallpaperModel.clear()
        var q = searchInput.text.trim()
        var count = 0
        for (var i = 0; i < allWallpapers.length; i++) {
            var w = allWallpapers[i]
            if (!Picker.matchesQuery(w, q)) continue
            wallpaperModel.append({
                name: w.name,
                path: w.path,
                thumb: w.thumb,
                active: (w.path === activeWallpaperPath)
            })
            count++
        }
        wallpaperCount = count
    }
}
