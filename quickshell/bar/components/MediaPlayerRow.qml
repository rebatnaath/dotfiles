import Quickshell.Widgets
import QtQuick

// media player row (album art, controls)
Row {
    id: mediaPlayerRow

    property string mediaStatusText: "None"
    property string mediaTitleText: ""
    property string mediaArtistText: ""
    property string artUrl: ""
    signal playPauseRequested()
    signal nextRequested()

    spacing: 12 * root.uiScale
    width: parent.width
    anchors.horizontalCenter: parent.horizontalCenter

    // Art(56) + play(34) + next(34) + 3*12 spacing = 160
    readonly property real reservedWidth: 160 * root.uiScale

    // Album art thumbnail
    Rectangle {
        width: 56 * root.uiScale
        height: 56 * root.uiScale
        radius: 0
        color: "transparent"
        border.width: 1 * root.uiScale
        border.color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.35)

        ClippingRectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 0
            color: "transparent"

            Image {
                anchors.fill: parent
                anchors.margins: 2
                source: mediaPlayerRow.artUrl
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                cache: true
                visible: status === Image.Ready && mediaPlayerRow.artUrl !== ""
            }

            Text {
                anchors.centerIn: parent
                text: "󰎇"
                font.family: root.fontFamily
                font.pixelSize: 24 * root.uiScale
                color: root.withAlpha(root.getColor("muted", "#a08d85"), 0.5)
                visible: mediaPlayerRow.artUrl === ""
            }
        }
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3 * root.uiScale
        width: parent.width - mediaPlayerRow.reservedWidth

        Text {
            text: mediaPlayerRow.mediaTitleText
            font.family: root.fontFamily
            font.pixelSize: 12 * root.uiScale
            font.bold: true
            color: root.getColor("fg", "#f0dfd8")
            elide: Text.ElideRight
            width: parent.width
        }

        Text {
            text: mediaPlayerRow.mediaArtistText
            font.family: root.fontFamily
            font.pixelSize: 10 * root.uiScale
            color: root.getColor("muted", "#a08d85")
            elide: Text.ElideRight
            width: parent.width
        }
    }

    RoundIconButton {
        anchors.verticalCenter: parent.verticalCenter
        iconText: mediaPlayerRow.mediaStatusText === "Playing" ? "󰏤" : "󰐊"
        onClicked: mediaPlayerRow.playPauseRequested()
    }

    RoundIconButton {
        anchors.verticalCenter: parent.verticalCenter
        iconText: "󰒭"
        onClicked: mediaPlayerRow.nextRequested()
    }
}
