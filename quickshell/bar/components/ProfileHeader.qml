import Quickshell
import Quickshell.Widgets
import QtQuick

// QuickMenu header: profile picture + username on the left, and the wallpaper,
// notification and power buttons on the right. Emits one signal per button so
// the parent owns the page-switching logic.
Item {
    id: profileHeader

    readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME") || "user"
    readonly property string avatarUrl: "file:///var/lib/AccountsService/icons/" + userName

    signal wallpaperRequested()
    signal notificationsRequested()
    signal powerMenuRequested()
    signal clipboardRequested()
    signal settingsRequested()

    width: parent.width
    height: 48 * root.uiScale
    anchors.horizontalCenter: parent.horizontalCenter

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12 * root.uiScale

        // Circle outline stays the same size; the photo is enlarged beyond it so
        // it crops tighter (zoomed-in look). ClippingRectangle clips to the
        // circle (plain `clip` only clips to a square).
        Rectangle {
            width: 48 * root.uiScale
            height: 48 * root.uiScale
            radius: 24
            color: "transparent"
            border.width: 1 * root.uiScale
            border.color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.5)

            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: width / 2
                color: "transparent"

                Image {
                    anchors { fill: parent; margins: -16 }
                    source: profileHeader.avatarUrl
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2 * root.uiScale

            Text {
                text: profileHeader.userName
                font.family: root.fontFamily
                font.pixelSize: 14 * root.uiScale
                font.bold: true
                color: root.getColor("fg", "#f0dfd8")
            }

            Text {
                text: "@nixos"
                font.family: root.fontFamily
                font.pixelSize: 11 * root.uiScale
                color: root.getColor("muted", "#a08d85")
            }
        }
    }

    IconButton {
        iconText: "\uF03E"
        isActive: root.isWallpaperPageOpen
        anchors.right: settingsButton.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        onClicked: profileHeader.wallpaperRequested()
    }

    IconButton {
        id: settingsButton
        iconText: "\uF013"
        isActive: root.isSettingsPageOpen
        anchors.right: clipboardButton.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        onClicked: profileHeader.settingsRequested()
    }

    IconButton {
        id: clipboardButton
        iconText: "󰅪"
        isActive: root.isClipboardPageOpen
        anchors.right: notificationButton.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        onClicked: profileHeader.clipboardRequested()
    }

    IconButton {
        id: notificationButton
        iconText: root.isDndEnabled ? "󰂛" : "󰂝"
        isActive: root.isNotificationPageOpen
        anchors.right: powerMenuButton.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        onClicked: profileHeader.notificationsRequested()
    }

    IconButton {
        id: powerMenuButton
        iconText: "󰐥"
        isActive: root.isPowerPageOpen
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        onClicked: profileHeader.powerMenuRequested()
    }
}
