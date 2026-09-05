import Quickshell
import QtQuick
import QtQuick.Effects
import "../components"

// notification popups, auto-dismissing, stacked upward
PanelWindow {
    id: notificationPopup
    // mirror OSD card width
    property real cardWidth: 311
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    // top-right when bar is on top/full-width, top-left otherwise
    readonly property bool atTop: (root.barSide === "top" || root.barFullWidth)
    readonly property bool atRight: root.barFullWidth
    anchors {
        top: atTop
        bottom: !atTop
        right: atRight
        left: !atRight
    }
    margins {
        top: atTop ? (root.barFullWidth ? 62 * root.uiScale : 9 * root.uiScale) : 0
        bottom: atTop ? 0 : 9 * root.uiScale
        left: atRight ? 0 : root.windowGap * root.uiScale
        right: atRight ? root.windowGap * root.uiScale : 0
    }
    // match OSD width
    implicitWidth: notificationPopup.cardWidth
    implicitHeight: popupList.contentHeight
    visible: notificationPopupModel.count > 0

    ListView {
        id: popupList
        width: notificationPopup.cardWidth
        height: popupList.contentHeight
        // clip off for shadow room
        clip: false
        anchors { top: parent.top; left: parent.left }
        spacing: 5
        model: notificationPopupModel
        interactive: false

        delegate: Item {
            required property var modelData
            width: popupList.width
            height: 54 * root.uiScale

            // hard offset shadow
            RectangularShadow {
                anchors.fill: card
                radius: 0
                color: "#000000"
                blur: 0
                spread: 0
                offset: Qt.vector2d(8 * root.uiScale, 8 * root.uiScale)
                visible: root.osdShadow
            }

            Rectangle {
                id: card
                anchors {
                    left: parent.left
                    right: parent.right
                    rightMargin: 8 * root.uiScale
                    bottom: parent.bottom
                    bottomMargin: 8 * root.uiScale
                }
                height: 46 * root.uiScale
                radius: root.frameRadius
                color: root.getColor("bg", "#1a120e")
                Behavior on color { ColorAnimation { duration: 120 } }

                AccentBorder {
                    cornerRadius: root.frameRadius
                    visible: root.osdBorder
                }

                Row {
                    id: popupRow
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                    anchors.leftMargin: 8 * root.uiScale
                    anchors.rightMargin: 8 * root.uiScale
                    spacing: 8 * root.uiScale

                    Rectangle {
                        id: appIconBox
                        width: 30 * root.uiScale
                        height: 30 * root.uiScale
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.14)
                        border.width: 1
                        border.color: root.withAlpha(root.getColor("accent", "#ffb691"), 0.4)
                        clip: true

                        // notification image or app initial
                        Image {
                            anchors.fill: parent
                            anchors.margins: 3 * root.uiScale
                            source: modelData.image
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
                        width: parent.width - appIconBox.width - parent.spacing
                        spacing: 2

                        Text {
                            text: modelData.appName
                            font.family: root.fontFamily
                            font.pixelSize: 10 * root.uiScale
                            font.bold: true
                            color: root.withAlpha(root.getColor("muted", "#a08d85"), 0.85)
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            // summary + body on one elided line
                            text: modelData.body !== "" ? modelData.summary + " — " + modelData.body : modelData.summary
                            font.family: root.fontFamily
                            font.pixelSize: 10 * root.uiScale
                            font.bold: true
                            color: root.getColor("fg", "#f0dfd8")
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.notification.dismiss()
                    onEntered: parent.color = root.mixHex(root.getColor("bg", "#1a120e"), root.getColor("accent", "#ffb691"), 0.12)
                    onExited: parent.color = root.getColor("bg", "#1a120e")
                }

                // Auto-dismiss after 5 seconds. Timer is per-delegate so each
                // notification has its own lifetime. The guard on modelData
                // prevents dismissing after the entry is removed from the model.
                Timer {
                    interval: 5000
                    running: true
                    onTriggered: {
                        if (modelData && modelData.notification) modelData.notification.dismiss()
                    }
                }
            }
        }
    }
}
