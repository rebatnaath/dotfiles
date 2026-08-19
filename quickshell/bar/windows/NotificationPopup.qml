import Quickshell
import QtQuick
import QtQuick.Effects
import "../components"

// Transient notification popups bottom-left, fed by the shared
// notificationPopupModel (owned by shell.qml). Cards stack upward with a 5px
// gap, styled like the bar/OSD faces, each auto-dismissing.
PanelWindow {
    id: notificationPopup
    // Mirrors the OSD card width (set via shell.qml) so both popups match.
    property real cardWidth: 311
    color: "transparent"
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    // Vertically at the top when the bar is on top or is full-width; horizontally
    // on the right when full-width or nerv (nerv shares the top-right under the
    // OSD). Non-full-width top bar keeps notifications top-left beside the bar.
    readonly property bool atTop: (root.activeBar === "nerv"
        || root.barSide === "top" || root.barFullWidth)
    readonly property bool atRight: (root.activeBar === "nerv" || root.barFullWidth)
    anchors {
        top: atTop
        bottom: !atTop
        right: atRight
        left: !atRight
    }
    margins {
        top: atTop ? (root.barFullWidth ? 62 * root.uiScale
            : (root.activeBar === "nerv" ? 36 * root.uiScale : 9 * root.uiScale)) : 0
        bottom: atTop ? 0 : 9 * root.uiScale
        left: atRight ? 0 : root.windowGap
        right: atRight ? (root.activeBar === "nerv" ? (root.windowGap + 8) * root.uiScale : root.windowGap) : 0
    }
    // Width matches the OSD (in nerv the shadow is hidden, so there is no +8
    // extra room here — mirroring the OSD keeps both panes pixel-aligned).
    implicitWidth: notificationPopup.cardWidth
    implicitHeight: popupList.contentHeight
    visible: notificationPopupModel.count > 0

    ListView {
        id: popupList
        width: notificationPopup.cardWidth
        height: popupList.contentHeight
        // Let each card's shadow paint into the window's 8px right/bottom room.
        clip: false
        anchors { top: parent.top; left: parent.left }
        spacing: 5
        model: notificationPopupModel
        interactive: false

        delegate: Item {
            required property var modelData
            width: popupList.width
            height: 54 * root.uiScale

            // Same hard offset shadow as the bar/OSD; placed first to render
            // behind the card.
            RectangularShadow {
                anchors.fill: card
                radius: 0
                color: "#000000"
                blur: 0
                spread: 0
                offset: Qt.vector2d(8, 8)
                visible: root.osdShadow && root.activeBar !== "nerv"
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

                        // Show the notification image when provided, otherwise
                        // fall back to the app initial.
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
                            // summary + body combined on one elided line so the
                            // compact 46px card keeps the message without wrapping.
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

                Timer {
                    interval: 5000
                    running: true
                    // Guarded: the entry may already have been removed (user
                    // click / clear) while this timer was pending.
                    onTriggered: {
                        if (modelData && modelData.notification) modelData.notification.dismiss()
                    }
                }
            }
        }
    }
}
