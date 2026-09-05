import QtQuick

Column {
    id: settingsPage

    property string title: ""
    property string subtitle: ""
    property alias content: contentArea.data

    width: parent.width
    spacing: 6 * root.uiScale
    visible: false

    Text {
        width: parent.width
        text: settingsPage.title
        font.family: root.fontFamily
        font.pixelSize: 16 * root.uiScale
        font.bold: true
        color: root.getColor("fg", "#f0dfd8")
    }

    Text {
        visible: settingsPage.subtitle !== ""
        width: parent.width
        text: settingsPage.subtitle
        font.family: root.fontFamily
        font.pixelSize: 11 * root.uiScale
        color: root.getColor("muted", "#a08d85")
        bottomPadding: 10 * root.uiScale
    }

    Column {
        id: contentArea
        width: parent.width
        spacing: 12 * root.uiScale
    }
}
