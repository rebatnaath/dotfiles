import Quickshell
import Quickshell.Widgets
import QtQuick

// profile header (picture + buttons)
Item {
    id: profileHeader

    readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME") || "user"
    readonly property string hostName: {
        var h = Quickshell.env("HOSTNAME")
        if (!h) h = Quickshell.env("HOST")
        return h || "nixos"
    }
    readonly property string avatarUrl: "file:///var/lib/AccountsService/icons/" + userName

    signal notificationsRequested()
    signal powerMenuRequested()
    signal clipboardRequested()
    signal settingsRequested()
    signal screenshotRequested()
    signal caffeineRequested()
    property real itemRadius: 0

    width: parent.width
    height: 48 * root.uiScale
    anchors.horizontalCenter: parent.horizontalCenter

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12 * root.uiScale

        // circle-clipped photo
        Rectangle {
            width: 48 * root.uiScale
            height: 48 * root.uiScale
            radius: 24
            color: "transparent"
            border.width: 1 * root.uiScale
            border.color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.5)

            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: 1 * root.uiScale
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
                text: "@" + profileHeader.hostName
                font.family: root.fontFamily
                font.pixelSize: 11 * root.uiScale
                color: root.getColor("muted", "#a08d85")
            }
        }
    }

    IconButton {
        id: screenshotButton
        iconText: "\uF030"
        buttonRadius: profileHeader.itemRadius
        anchors.right: clipboardButton.left
        anchors.rightMargin: 8 * root.uiScale
        anchors.verticalCenter: parent.verticalCenter
        onClicked: profileHeader.screenshotRequested()
    }

    IconButton {
        id: clipboardButton
        iconText: "󰅪"
        isActive: root.isClipboardPageOpen
        buttonRadius: profileHeader.itemRadius
        anchors.right: notificationButton.left
        anchors.rightMargin: 8 * root.uiScale
        anchors.verticalCenter: parent.verticalCenter
        onClicked: profileHeader.clipboardRequested()
    }

    IconButton {
        id: notificationButton
        iconText: root.isDndEnabled ? "󰂛" : "󰂝"
        isActive: root.isNotificationPageOpen
        buttonRadius: profileHeader.itemRadius
        anchors.right: powerMenuButton.left
        anchors.rightMargin: 8 * root.uiScale
        anchors.verticalCenter: parent.verticalCenter
        onClicked: profileHeader.notificationsRequested()
    }

    IconButton {
        id: powerMenuButton
        iconText: "󰐥"
        isActive: root.isPowerPageOpen
        buttonRadius: profileHeader.itemRadius
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        onClicked: profileHeader.powerMenuRequested()
    }
}
