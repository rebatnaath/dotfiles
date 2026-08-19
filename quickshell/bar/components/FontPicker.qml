import Quickshell.Io
import QtQuick

// Searchable font picker: type to filter the installed (fontconfig) fonts; the
// top matches appear in-flow and are clickable. Choosing applies the font to
// quickshell + kitty via root (the caller wires chosen() to saveRiceSettings()).
// Implemented as a Column so the results expand the page instead of overlaying
// and being clipped by the scroll container.
Column {
    id: fontPicker

    property string currentFont: root.fontFamily
    property bool popupOpen: false
    property var fonts: []
    property var matching: []
    property int listHighlight: -1

    signal chosen(string fontFamily)

    width: parent.width
    spacing: 2 * root.uiScale

    // ---- Search field -----------------------------------------------------

    Rectangle {
        id: fieldBox
        width: fontPicker.width
        height: 44 * root.uiScale
        radius: 0
        color: "transparent"
        border.width: 1 * root.uiScale
        border.color: fontPicker.currentFont === root.fontFamily
            ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.5)
            : root.getColor("muted", "#a08d85")

        Text {
            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
            text: "Search fonts\u2026"
            font.family: root.fontFamily
            font.pixelSize: 12 * root.uiScale
            color: root.getColor("muted", "#a08d85")
            visible: field.text.length === 0
        }

        TextInput {
            id: field
            anchors { fill: parent; leftMargin: 14; rightMargin: 60 }
            verticalAlignment: TextInput.AlignVCenter
            color: root.getColor("fg", "#f0dfd8")
            font.family: root.fontFamily
            font.pixelSize: 13 * root.uiScale
            selectByMouse: true
            text: root.fontFamily

            onTextChanged: {
                root.fontFamily = text !== "" ? text : "GeistMono NFM"
                fontPicker.filterFonts()
            }
            onAccepted: {
                var t = field.text.trim()
                if (t !== "") fontPicker.applyFont(t)
                else fontPicker.popupOpen = false
            }
            Keys.onEscapePressed: fontPicker.popupOpen = false
            Keys.onUpPressed: fontPicker.listCursor(-1)
            Keys.onDownPressed: fontPicker.listCursor(1)
            Keys.onReturnPressed: fontPicker.applyFont(fontPicker.currentHighlight())
        }

        // Re-scan fontconfig (fc-list) so fonts installed since startup show up
        // without restarting the picker. FontAwesome glyph, clickable.
        Text {
            id: refreshIcon
            anchors.right: caret.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "\uF021"
            font.family: root.fontFamily
            font.pixelSize: 12 * root.uiScale
            color: refreshArea.hovered
                ? root.getColor("accent", "#ffb691")
                : root.getColor("muted", "#a08d85")
            MouseArea {
                id: refreshArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: fontPicker.refreshFonts()
            }
        }

        // Drop caret.
        Text {
            id: caret
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "\u25BE"
            font.family: root.fontFamily
            font.pixelSize: 12 * root.uiScale
            color: root.getColor("muted", "#a08d85")
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    fontPicker.filterFonts()
                    fontPicker.popupOpen = !fontPicker.popupOpen
                }
            }
        }
    }

    // ---- In-flow results --------------------------------------------------

    Repeater {
        model: fontPicker.popupOpen ? fontPicker.matching : []

        Rectangle {
            width: fontPicker.width
            height: 28 * root.uiScale
            color: itemMouse.hovered || fontPicker.listHighlight === index
                ? root.withAlpha(root.getColor("accent", "#ffb691"), 0.3)
                : root.getColor("bg", "#1a120e")
            radius: 0

            MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: fontPicker.applyFont(modelData)
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: modelData
                font.family: modelData
                font.pixelSize: 12 * root.uiScale
                color: root.getColor("fg", "#f0dfd8")
                elide: Text.ElideRight
            }
        }
    }

    // ---- Helpers ----------------------------------------------------------

    Process {
        id: fcProc
        command: ["bash", "-c", "fc-list : family | cut -d, -f1 | sort -u"]
        stdout: StdioCollector {
            id: fcOut
            waitForEnd: true
            onStreamFinished: {
                fontPicker.collectFonts(fcOut.text)
                fontPicker.filterFonts()
            }
        }
    }

    function refreshFonts() {
        fcProc.running = true
    }

    function collectFonts(text) {
        var lines = text.trim().split("\n")
        var seen = {}, out = []
        for (var i = 0; i < lines.length; i++) {
            var f = lines[i].trim()
            if (f && !seen[f]) { seen[f] = 1; out.push(f) }
        }
        fontPicker.fonts = out
    }

    function filterFonts() {
        var q = field.text.trim().toLowerCase()
        var out = []
        for (var i = 0; i < fontPicker.fonts.length; i++) {
            if (fontPicker.fonts[i].toLowerCase().indexOf(q) >= 0) out.push(fontPicker.fonts[i])
        }
        fontPicker.matching = out.slice(0, 8)
        fontPicker.listHighlight = -1
        fontPicker.popupOpen = out.length > 0
    }

    function applyFont(name) {
        field.text = name
        field.deselect()
        fontPicker.currentFont = name
        fontPicker.popupOpen = false
        fontPicker.chosen(name)
    }

    function currentHighlight() {
        var m = fontPicker.matching
        if (fontPicker.listHighlight >= 0 && fontPicker.listHighlight < m.length) return m[fontPicker.listHighlight]
        return m.length ? m[0] : field.text.trim()
    }

    function listCursor(delta) {
        var m = fontPicker.matching
        if (m.length === 0) return
        fontPicker.listHighlight += delta
        if (fontPicker.listHighlight < 0) fontPicker.listHighlight = m.length - 1
        if (fontPicker.listHighlight >= m.length) fontPicker.listHighlight = 0
    }

    Component.onCompleted: {
        field.text = root.fontFamily
        fcProc.running = true
    }
}