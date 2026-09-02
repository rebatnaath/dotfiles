import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import "components"
import "picker-data.js" as Picker

PanelWindow {
    id: menuWindow
    color: "transparent"
    aboveWindows: true
    // Accept keyboard focus while open so the wallpaper search field can be
    // typed into (PanelWindow defaults to focusable: false, which silently
    // sends keystrokes to whatever app is behind the menu).
    focusable: true
    // nerv uses the same control center with red theme.
    visible: root.isQuickMenuOpen
    anchors { top: true; left: true; right: true; bottom: true }
    margins { top: 0; bottom: 0; left: 0; right: 0 }

    // Card geometry, named so the height formula below reads clearly.
    readonly property int cardTopPadding: Math.round(17 * root.uiScale)
    readonly property int profileHeaderHeight: Math.round(48 * root.uiScale)
    readonly property int menuColumnSpacing: Math.round(16 * root.uiScale)
    readonly property int dividerHeight: 1
    readonly property int cardBottomPadding: Math.round(14 * root.uiScale)
    // Space the media section (divider 1 + row 56 + 2 spacing gaps) takes when
    // it is visible; added while hidden so the card stays the same size in
    // both cases.
    readonly property int hiddenMediaSectionHeight: Math.round(89 * root.uiScale)

    // Region screenshot via grim + slurp.
    Process {
        id: screenshotProc
    }

    // Apply a wallpaper: --fast swaps the wallpaper instantly and runs the
    // full retheme (matugen + bar restart) in the background.
    Process {
        id: wallpaperApplyProc
    }

    // Reload the wallpaper list at runtime: regenerates thumbs + data via
    // `wall-pick --data-only` and parses the JSON it prints to stdout.
    Process {
        id: wallpaperReloadProc
        command: ["bash", "-c", "$HOME/.config/sway/scripts/wall-pick --data-only"]
        stdout: StdioCollector {
            id: wallpaperReloadCollector
            waitForEnd: true
            onStreamFinished: wallpaperPage.setWallpapersFromJson(wallpaperReloadCollector.text)
        }
    }

    function applyWallpaper(path) {
        wallpaperApplyProc.command = [Picker.THEME_SWITCH, "--fast", path]
        wallpaperApplyProc.startDetached()
    }

    // Toggle a quick-menu page; opening one closes the others. Reloads the
    // wallpaper list only when the wallpaper page becomes visible.
    function togglePage(pageName, reloadWallpapers) {
        var pageProperty = "is" + pageName + "PageOpen"
        var wasOpen = root[pageProperty]
        root.closeAllPages()
        if (!wasOpen) {
            root[pageProperty] = true
            if (reloadWallpapers) wallpaperPage.setWallpapers(Picker.WALLS, Picker.ACTIVE)
        }
    }

    // Clicking outside the card closes the menu.
    MouseArea {
        anchors.fill: parent
        onClicked: root.isQuickMenuOpen = false
    }

    // Same hard offset shadow as the bar and OSD (box-shadow: 8px 8px 0 #000),
    // so the quick menu reads as a sibling of the bar.
    RectangularShadow {
        anchors.fill: menuCard
        radius: 0
        color: "#000000"
        blur: 0
        spread: 0
        offset: Qt.vector2d(8, 8)
        visible: root.quickMenuShadow
    }

    Rectangle {
        id: menuCard
        // Appear beside the bar: below it when the bar is at the top, above
        // it when the bar is at the bottom. Right edge aligned with "controls":
        // in non-full-width the bar is inset by barSideMargin, but in full-width
        // it spans edge-to-edge so align to the band the ctrls label sits in.
        x: root.barFullWidth
            ? Quickshell.screens[0].width - 12 * root.uiScale - menuCard.width
            : Quickshell.screens[0].width - root.barSideMargin - 12 * root.uiScale - menuCard.width
        y: {
            var screenH = Quickshell.screens[0].height
            // Hardcoded face positions per bar type.
            // nerv: face=60px, margin=16/26, no shadow
            // fox/lonely: face=46px, margin=9, shadow=8 when enabled
            var barBottom, barTop
            if (root.activeBar === "nerv") {
                barBottom = 76 * root.uiScale
                barTop = screenH - 86 * root.uiScale
            } else if (root.barFullWidth) {
                barBottom = (root.barShadow ? 54 : 46) * root.uiScale
                barTop = screenH - (root.barShadow ? 54 : 46) * root.uiScale
            } else {
                barBottom = (root.barShadow ? 63 : 55) * root.uiScale
                barTop = screenH - (root.barShadow ? 63 : 55) * root.uiScale
            }
            return root.barSide === "top" ? barBottom : Math.max(0, barTop - menuCard.height)
        }
        width: 400 * root.uiScale
        // Constant height across all pages: the main content (system controls,
        // incl. the media section) sets the size; the power/notification/
        // wallpaper pages render inside it without resizing the card.
        height: cardTopPadding + profileHeaderHeight + menuColumnSpacing + dividerHeight
            + menuColumnSpacing + systemControlsColumn.height
            + (root.mediaStatus === "None" ? hiddenMediaSectionHeight : 0)
            + cardBottomPadding
        radius: root.frameRadius
        color: root.getColor("bg", "#1a120e")

        AccentBorder {
            cornerRadius: root.frameRadius
            visible: root.quickMenuBorder
        }

        // Consume clicks on the card so they don't reach the background closer
        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => mouse.accepted = true
        }

        Column {
            id: menuColumn
            anchors.top: parent.top
            anchors.topMargin: cardTopPadding
            anchors.horizontalCenter: parent.horizontalCenter
            width: 366 * root.uiScale
            spacing: menuColumnSpacing

            ProfileHeader {
                onWallpaperRequested: menuWindow.togglePage("Wallpaper", true)
                onNotificationsRequested: menuWindow.togglePage("Notification")
                onClipboardRequested: menuWindow.togglePage("Clipboard")
                onSettingsRequested: menuWindow.togglePage("Settings")
                onPowerMenuRequested: menuWindow.togglePage("Power")
            }

            Divider {}

            // System controls: pills, sliders and media player.
            Column {
                id: systemControlsColumn
                spacing: menuColumnSpacing
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !root.isPowerPageOpen && !root.isNotificationPageOpen && !root.isWallpaperPageOpen && !root.isClipboardPageOpen && !root.isSettingsPageOpen

                Row {
                    spacing: 10
                    width: parent.width
                    anchors.horizontalCenter: parent.horizontalCenter

                    PillButton {
                        iconText: root.wifiName === "" ? "󰖪" : "󰖩"
                        labelText: root.isWifiConnecting ? "Connecting…" : (root.wifiName === "" ? "Disconnected" : root.wifiName)
                        isChecked: root.wifiName !== ""
                        onClicked: root.toggleWifi()
                    }

                    PillButton {
                        iconText: root.bluetoothEnabled ? "󰂯" : "󰂲"
                        labelText: root.isBluetoothConnecting ? "Connecting…" : (root.bluetoothEnabled ? (root.bluetoothDeviceName === "" ? "On" : root.bluetoothDeviceName) : "Off")
                        isChecked: root.bluetoothEnabled
                        onClicked: root.toggleBluetooth()
                    }

                    PillButton {
                        iconText: root.isDndEnabled ? "󰂛" : "󰂝"
                        labelText: root.isDndEnabled ? "DND On" : "DND Off"
                        isChecked: root.isDndEnabled
                        iconUsesAccent: true
                        onClicked: root.toggleDnd()
                    }
                }

                Row {
                    spacing: 10
                    width: parent.width
                    anchors.horizontalCenter: parent.horizontalCenter

                    PillButton {
                        iconText: root.isNightLightEnabled ? "󰛨" : "󰛩"
                        labelText: "Night Light"
                        isChecked: root.isNightLightEnabled
                        iconUsesAccent: true
                        onClicked: root.toggleNightLight()
                    }

                    PillButton {
                        iconText: "\uF030"
                        labelText: "Screenshot"
                        isActive: true
                        onClicked: {
                            root.isQuickMenuOpen = false
                            screenshotProc.command = ["bash", "-c", "mkdir -p \"$HOME/Pictures/Screenshots/sway\" && grim -g \"$(slurp)\" - | tee \"$HOME/Pictures/Screenshots/sway/screenshot-$(date +%Y-%m-%d_%H%M%S).png\" | wl-copy"]
                            screenshotProc.startDetached()
                        }
                    }

                    BatteryPill {
                        batteryLevel: root.batteryLevel
                        batteryStatus: root.batteryStatus
                    }
                }

                SliderRow {
                    iconText: root.isVolumeMuted ? "ﱝ" : ""
                    iconDimmed: root.isVolumeMuted
                    value: root.isVolumeMuted || root.volume < 0 ? 0 : root.volume
                    valueText: root.isVolumeMuted ? "Muted" : (root.volume < 0 ? "--" : root.volume + "%")
                    onValuePreviewed: (newValue) => {
                        root.volume = newValue
                        root.isVolumeDragging = true
                    }
                    onValueCommitted: (newValue) => {
                        root.isVolumeDragging = false
                        root.setVolume(newValue)
                    }
                }

                SliderRow {
                    iconText: "󰃠"
                    value: root.brightnessLevel
                    showHandle: false
                    onValuePreviewed: (newValue) => root.setBrightness(newValue)
                }

                Divider {
                    visible: root.mediaStatus !== "None"
                }

                MediaPlayerRow {
                    visible: root.mediaStatus !== "None"
                    mediaStatusText: root.mediaStatus
                    mediaTitleText: root.mediaTitle || root.mediaName || "Unknown"
                    mediaArtistText: root.mediaArtist || "Unknown Artist"
                    artUrl: root.mediaArtUrl || ""
                    onPlayPauseRequested: root.toggleMediaPlay()
                    onNextRequested: {
                        mediaNextProc.command = [root.swayScriptsDir + "/media-control", "Next"]
                        mediaNextProc.startDetached()
                        root.mediaResync.restart()
                    }
                }
            }

            PowerPage {
                visible: root.isPowerPageOpen
            }

            NotificationPage {
                visible: root.isNotificationPageOpen
            }

            ClipboardPage {
                visible: root.isClipboardPageOpen
            }

            SettingsPage {
                visible: root.isSettingsPageOpen
                width: parent.width
                height: menuCard.height - (cardTopPadding + profileHeaderHeight
                    + menuColumnSpacing + dividerHeight + menuColumnSpacing + cardBottomPadding)
            }

            WallpaperPage {
                id: wallpaperPage
                visible: root.isWallpaperPageOpen
                gridAvailableHeight: menuCard.height - (cardTopPadding + profileHeaderHeight
                    + menuColumnSpacing + dividerHeight + menuColumnSpacing + cardBottomPadding
                    + wallpaperPage.headerRowHeight + wallpaperPage.searchRowHeight
                    + 2 * wallpaperPage.pageSpacing)
                onReloadRequested: {
                    if (!wallpaperReloadProc.running) {
                        wallpaperReloadProc.running = true
                    }
                }
                onWallpaperChosen: (path) => applyWallpaper(path)
            }
        }
    }
}
