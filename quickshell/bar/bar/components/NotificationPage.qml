import QtQuick

// notification history page
Column {
    id: notificationPageColumn
    spacing: 10 * root.uiScale
    width: parent.width
    anchors.horizontalCenter: parent.horizontalCenter
    property real itemRadius: 0

    function fmtTime(ts) {
        if (!ts) return ""
        var d = new Date(ts)
        var h = d.getHours()
        var m = d.getMinutes()
        return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
    }

    Item {
        width: parent.width
        height: 34 * root.uiScale

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Notifications"
            font.family: root.fontFamily
            font.pixelSize: 13 * root.uiScale
            font.bold: true
            color: root.getColor("accent", "#ffb691")
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 8 * root.uiScale
            anchors.verticalCenter: parent.verticalCenter
            text: notificationListModel.count
            font.family: root.fontFamily
            font.pixelSize: 12 * root.uiScale
            color: root.getColor("muted", "#a08d85")
        }

        Text {
            id: clearButton
            anchors.right: parent.right
            anchors.rightMargin: 6 * root.uiScale
            anchors.verticalCenter: parent.verticalCenter
            text: "Clear"
            font.family: root.fontFamily
            font.pixelSize: 11 * root.uiScale
            font.bold: true
            color: root.getColor("accent", "#ffb691")
            visible: notificationListModel.count > 0
            opacity: clearArea.hovered ? 1.0 : 0.7

            // underline hint
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1 * root.uiScale
                color: root.getColor("accent", "#ffb691")
            }

            MouseArea {
                id: clearArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clearNotifications()
            }
        }
    }

    ListView {
        width: parent.width
        height: 226 * root.uiScale
        spacing: 8 * root.uiScale
        topMargin: 1
        bottomMargin: 1
        clip: true
        model: notificationListModel

        delegate: Rectangle {
            required property var modelData
            required property int index
            width: ListView.view.width
            height: 52 * root.uiScale
            radius: notificationPageColumn.itemRadius
            color: "transparent"
            border.width: 1 * root.uiScale
            border.color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.3)

            Row {
                anchors.fill: parent
                anchors.margins: 8 * root.uiScale
                spacing: 8 * root.uiScale

                // app icon box
                Rectangle {
                    id: appIconBox
                    width: 30 * root.uiScale
                    height: 30 * root.uiScale
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.14)
                    border.width: 1 * root.uiScale
                    border.color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.4)
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 3 * root.uiScale
                        source: modelData.image !== "" ? modelData.image : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: modelData.image !== ""
                        asynchronous: true
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.appName.charAt(0).toUpperCase()
                        font.family: root.fontFamily
                        font.pixelSize: 15 * root.uiScale
                        font.bold: true
                        color: root.getColor("accent", "#ffb691")
                        visible: modelData.image === ""
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - appIconBox.width - timeText.width - parent.spacing * 2

                    Text {
                        text: modelData.summary
                        font.family: root.fontFamily
                        font.pixelSize: 12 * root.uiScale
                        font.bold: true
                        color: root.getColor("fg", "#f0dfd8")
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: modelData.body
                        font.family: root.fontFamily
                        font.pixelSize: 10 * root.uiScale
                        color: root.getColor("muted", "#a08d85")
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }

                // time (fixed slot)
                Text {
                    id: timeText
                    width: 40 * root.uiScale
                    horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                    text: notificationPageColumn.fmtTime(modelData.timestamp)
                    font.family: root.fontFamily
                    font.pixelSize: 9 * root.uiScale
                    color: root.getColor("muted", "#a08d85")
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                // dismiss + remove from model
                onClicked: {
                    var item = notificationListModel.get(index)
                    if (item && item.notification) {
                        try { item.notification.dismiss() } catch (e) {}
                    }
                    notificationListModel.remove(index)
                }
                onEntered: parent.color = root.withAlpha(root.getColor("accent", "#ffb691"), 0.14)
                onExited: parent.color = "transparent"
            }
        }
    }
}