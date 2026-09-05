import Quickshell.Io
import QtQuick

// clipboard history page (cliphist)
Column {
    id: clipboardColumn
    spacing: 10 * root.uiScale
    width: parent.width
    anchors.horizontalCenter: parent.horizontalCenter

    ListModel { id: clipboardModel }

    Process {
        id: clipListProc
        stdout: StdioCollector { id: clipListOut; waitForEnd: true; onStreamFinished: parseList(clipListOut.text) }
    }

    Process {
        id: clipCopyProc
    }

    Process {
        id: clipDeleteProc
    }

    // parse cliphist list output
    function parseList(text) {
        var entries = []
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            if (line === "") continue
            // split on first tab: index + preview
            var tab = line.indexOf("\t")
            if (tab < 0) continue
            entries.push({
                index: line.substring(0, tab).trim(),
                preview: line.substring(tab + 1)
            })
        }

        // skip rebuild if nothing changed
        if (entries.length === clipboardModel.count) {
            var same = true
            for (var j = 0; j < entries.length; j++) {
                if (clipboardModel.get(j).index !== entries[j].index ||
                    clipboardModel.get(j).preview !== entries[j].preview) {
                    same = false
                    break
                }
            }
            if (same) return
        }

        // rebuild, keep scroll position
        var scrollPos = clipboardList.contentY
        clipboardModel.clear()
        for (var k = 0; k < entries.length; k++) {
            clipboardModel.append(entries[k])
        }
        clipboardList.contentY = scrollPos
    }

    // quickshell gives child procs a stripped PATH, so re-add my nix bins
    readonly property string pathPrepend: 'PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:$PATH"'

    function refresh() {
        clipListProc.command = ["bash", "-c", pathPrepend + " ; cliphist list | head -n 25"]
        clipListProc.running = true
    }

    function copyEntry(entry) {
        // sanitize: numeric only
        if (!/^\d+$/.test(entry)) return
        clipCopyProc.command = ["bash", "-c", pathPrepend + " ; cliphist decode <<< \"$1\" | wl-copy 2>/dev/null", "clip", entry]
        clipCopyProc.startDetached()
    }

    function deleteEntry(entry) {
        if (!/^\d+$/.test(entry)) return
        clipDeleteProc.command = ["bash", "-c", pathPrepend + " ; printf '%s' \"$1\" | cliphist delete 2>/dev/null", "clip", entry]
        clipDeleteProc.startDetached()
    }

    Row {
        width: parent.width
        height: 34 * root.uiScale
        spacing: 8 * root.uiScale

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Clipboard"
            font.family: root.fontFamily
            font.pixelSize: 13 * root.uiScale
            font.bold: true
            color: root.getColor("accent", "#ffb691")
        }

        Text {
            id: countLabel
            anchors.verticalCenter: parent.verticalCenter
            text: clipboardModel.count
            font.family: root.fontFamily
            font.pixelSize: 12 * root.uiScale
            color: root.getColor("muted", "#a08d85")
        }
    }

    Text {
        id: emptyLabel
        width: parent.width
        visible: clipboardModel.count === 0
        text: "Clipboard is empty — copy something first."
        font.family: root.fontFamily
        font.pixelSize: 10 * root.uiScale
        color: root.getColor("muted", "#a08d85")
        wrapMode: Text.WordWrap
    }

    ListView {
        id: clipboardList
        width: parent.width
        height: 226 * root.uiScale
        spacing: 2 * root.uiScale
        topMargin: 1
        bottomMargin: 1
        clip: true
        model: clipboardModel

        delegate: Rectangle {
            required property var modelData
            width: ListView.view.width
            height: 28 * root.uiScale
            radius: 0
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: 3
                anchors.rightMargin: 3
                color: "transparent"

                Text {
                    id: previewText
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 10 * root.uiScale
                    color: root.getColor("fg", "#f0dfd8")
                    // single-line preview
                    text: modelData.preview.replace(/\n/g, " ")
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        clipboardColumn.deleteEntry(modelData.index)
                        clipboardModel.remove(index)
                    } else {
                        clipboardColumn.copyEntry(modelData.index)
                    }
                }
                onEntered: parent.color = root.withAlpha(root.getColor("accent", "#ffb691"), 0.14)
                onExited: parent.color = "transparent"
            }
        }
    }

    onVisibleChanged: if (visible) refresh()

    // re-poll while page is open
    Timer {
        running: clipboardColumn.visible
        interval: 5000
        repeat: true
        onTriggered: clipboardColumn.refresh()
    }
}