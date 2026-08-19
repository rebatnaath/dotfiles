import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import "colors.js" as Colors

// Secure lockscreen (ext_session_lock_v1). Uses the current wallpaper,
// slightly blurred, as the backdrop (same framing as sway's lock.sh), with the
// profile picture + username centered above a password field. Styled to match
// the bar (same palette, fonts and accent border).
ShellRoot {
    id: root

    // ---- Theme (reactive copies of the bar's palette) ---------------------
    property string colorBg: Colors.COLORS.bg
    property string colorFg: Colors.COLORS.fg
    property string colorAccent: Colors.COLORS.accent
    property string colorMuted: Colors.COLORS.muted

    // Global ui font (kept in sync with the bar via bar/settings.js).
    property string fontFamily: "GeistMono NFM"

    FileView {
        id: settingsFile
        path: "/home/oryza/.config/quickshell/bar/settings.js"
        preload: true
        blockAllReads: true
        watchChanges: false
    }

    function applyFont(): void {
        settingsFile.reload()
        var m = /fontFamily:[ \t]*"([^"]*)"/.exec(settingsFile.text())
        if (m) root.fontFamily = m[1]
    }

    Timer {
        interval: 400
        running: true
        repeat: true
        onTriggered: root.applyFont()
    }

    // Current wallpaper (symlink kept in sync by theme-switch).
    readonly property string wallpaperPath: "/home/oryza/.cache/current-wallpaper"
    // Profile avatar (same asset as the bar's ProfileHeader).
    readonly property string avatarPath: "file:///var/lib/AccountsService/icons/oryza"

    // ---- Clock -------------------------------------------------------------
    property string timeText: ""
    property string dateText: ""

    function updateClock() {
        var d = new Date()
        var days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
        var months = ["January","February","March","April","May","June","July","August","September","October","November","December"]
        var h = d.getHours(), m = d.getMinutes()
        root.timeText = h + ":" + (m < 10 ? "0" : "") + m
        root.dateText = days[d.getDay()].toLowerCase() + ", " + months[d.getMonth()].toLowerCase() + " " + d.getDate()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updateClock()
    }

    // ---- Now playing (mirrors the bar's media state + polling) --------------
    property string mediaStatus: "None"
    property string mediaTitle: ""
    property string mediaArtist: ""
    property string mediaName: ""
    property string mediaArtUrl: ""

    Process {
        id: mediaProc
        stdout: StdioCollector { id: mediaOutput; waitForEnd: true }
        onExited: (code, status) => {
            var out = mediaOutput.text.trim()
            var parts = out.split("|")
            root.mediaStatus = parts.length > 0 ? parts[0] : "None"
            root.mediaTitle = parts.length > 1 ? parts[1] : ""
            root.mediaArtist = parts.length > 2 ? parts[2] : ""
            root.mediaName = parts.length > 3 ? parts[3] : ""
            root.mediaArtUrl = parts.length > 4 ? parts[4] : ""
        }
    }

    Process { id: mediaPlayPauseProc }
    Process { id: mediaNextProc }

    function pollMedia() {
        mediaProc.exec(["/home/oryza/.config/sway/scripts/now-playing"])
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.pollMedia()
    }

    function getColor(key, fallback) {
        var p = "color" + key.charAt(0).toUpperCase() + key.slice(1)
        return root[p] || fallback
    }

    function withAlpha(colorHex, alpha) {
        var r = parseInt(colorHex.substring(1, 3), 16)
        var g = parseInt(colorHex.substring(3, 5), 16)
        var b = parseInt(colorHex.substring(5, 7), 16)
        return Qt.rgba(r / 255, g / 255, b / 255, alpha)
    }

    // ---- Unlock (PAM authentication) -------------------------------------

    // Real password check against PAM using quickshell's built-in PamContext
    // (same mechanism as the official quickshell lockscreen example). This
    // talks to pam_unix directly — no subprocess, so there's no "Process reuse"
    // problem and every attempt is fresh. We must NOT leak the password: it's
    // only ever passed to respond() and never logged.
    property bool authPending: false
    property string failedText: ""

    // Re-shakes the password field's text so it's cleared on a wrong password.
    signal authSig()

    PamContext {
        id: pam
        configDirectory: "pam"
        config: "password.conf"
        // pam_unix asks for the password prompt; answer it with what we entered.
        onPamMessage: {
            if (pam.responseRequired) pam.respond(pamPassword)
        }
        onCompleted: result => {
            root.authPending = false
            var ok = result === PamResult.Success
            root.failedText = ok ? "" : "Incorrect password — try again"
            if (ok) root.finishUnlock()
            else root.authSig()
        }
    }
    property string pamPassword: "" // the password for the current attempt

    // Launch a PAM check with the entered password.
    function tryUnlock(password) {
        if (authPending) return
        authPending = true
        failedText = ""
        pamPassword = password
        pam.start()
    }

    // Called only after a successful PAM check. Release the session lock and
    // quit (mirrors swaylock: it runs until unlocked, then exits so swayidle /
    // super+L can lock again cleanly). Must set locked=false before quitting,
    // otherwise ext_session_lock_v1 paints the fallback lockscreen.
    function finishUnlock() {
        lock.locked = false
        Qt.quit()
    }

    // ---- Session lock ------------------------------------------------------

    WlSessionLock {
        id: lock
        // One WlSessionLockSurface per screen. Defined inline so this surface
        // captures the shell's `root` scope (a separate file has no access to
        // it). `locked` starts false so the compositor stays unlocked during
        // load; the keybind turns it on. Actually lock only when launched by
        // lock.sh (QS_LOCK=1) — so a manual launch/reload for testing never
        // leaves the solid-colour fallback lockscreen.
        surface: lockSurfaceTemplate
        Component.onCompleted: {
            lock.locked = (Quickshell.env("QS_LOCK") === "1")
            root.pollMedia()
        }
    }

    Component {
        id: lockSurfaceTemplate
        WlSessionLockSurface {
            id: surface

            // ---- Screenshot keybinds -----------------------------------------
            // When ext-session-lock is active the surface owns the keyboard, so
            // sway's bindsym never fires (Super+Shift+S used to type "s" into the
            // password field). Re-bind those combos here and run the same grim
            // commands directly. Shortcut is focus-independent, so it fires even
            // while the password TextField has focus.
            Process { id: scratchRegionshot } // unbounded reuse; fired detached
            Process { id: scratchFullshot }

            Shortcut {
                sequence: "Meta+Shift+S"
                onActivated: {
                    scratchRegionshot.command = ["bash", "-c",
                        'mkdir -p "$HOME/Pictures/Screenshots/sway" && grim -g "$(slurp)" - | tee "$HOME/Pictures/Screenshots/sway/screenshot-$(date +%Y-%m-%d_%H%M%S).png" | wl-copy']
                    scratchRegionshot.startDetached()
                }
            }
            Shortcut {
                sequence: "Meta+Shift+F10"
                onActivated: {
                    scratchFullshot.command = ["bash", "-c",
                        'mkdir -p "$HOME/Pictures/Screenshots/sway" && grim - | tee "$HOME/Pictures/Screenshots/sway/screenshot-$(date +%Y-%m-%d_%H%M%S).png" | wl-copy']
                    scratchFullshot.startDetached()
                }
            }

            // ---- Backdrop: current wallpaper, pre-blurred ------------------
            // lock.sh writes a blurred, screen-sized copy of the wallpaper to
            // ~/.cache/lock-blur.png before launching us, so no runtime blur is
            // needed (reliable + fast). Fall back to the raw wallpaper if the
            // blurred copy isn't there yet.
            Image {
                id: wallpaper
                anchors.fill: parent
                source: "file:///home/oryza/.cache/lock-blur.png"
                fillMode: Image.PreserveAspectCrop
                smooth: true
                cache: false
                onStatusChanged: if (status === Image.Error) {
                    source = "file://" + root.wallpaperPath
                }
            }

            // Thin dark overlay so the artwork sits on a softer backdrop.
            Rectangle {
                anchors.fill: parent
                color: root.withAlpha(root.getColor("bg", "#15130b"), 0.60)
            }

            // ---- Clock: literal top of the screen ---------------------------
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 48
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.dateText
                    font.family: root.fontFamily
                    font.pixelSize: 14
                    color: root.withAlpha(root.getColor("muted", "#969080"), 0.95)
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.timeText
                    font.family: root.fontFamily
                    font.pixelSize: 72
                    font.bold: true
                    color: root.getColor("fg", "#e8e2d4")
                }
            }

            // ---- Centre content: login card -----------------------------------
            // Card that frames the whole login area (avatar + username +
            // password field), styled like the bar's surfaces: rounded bg with
            // an accent border + hard offset shadow (shadow is a sibling behind
            // the card, matching the bar/OSD/quickmenu).
            RectangularShadow {
                anchors.fill: loginCard
                radius: 0
                color: "#000000"
                blur: 0
                spread: 0
                offset: Qt.vector2d(8, 8)
            }

            Rectangle {
                id: loginCard
                // Horizontally centred; pushed down so it sits between the
                // screen's vertical centre and the bottom edge.
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: mediaCard.top
                anchors.bottomMargin: 54
                radius: 0
                width: loginCardContent.implicitWidth + 48
                height: loginCardContent.implicitHeight + 40
                color: root.getColor("bg", "#15130b")
                border.width: 1
                border.color: root.withAlpha(root.getColor("accent", "#dac76f"), 0.4)

                Column {
                    id: loginCardContent
                    anchors.centerIn: parent
                    spacing: 18
                    width: 320

                    // Profile picture: circle outline stays the same size, but the photo is
                    // enlarged beyond it so it crops tighter (zoomed-in look).
                    // ClippingRectangle clips to the circle (plain `clip` only
                    // clips to a square), so the enlarged image stays inside.
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 88
                        height: 88
                        radius: width / 2
                        color: "transparent"
                        border.width: 2
                        border.color: root.withAlpha(root.getColor("accent", "#dac76f"), 0.5)

                        ClippingRectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: width / 2
                            color: "transparent"

                            Image {
                                anchors { fill: parent; margins: -28 }
                                source: root.avatarPath
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                            }
                        }
                    }

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "oryza"
                            font.family: root.fontFamily
                            font.pixelSize: 20
                            font.bold: true
                            color: root.getColor("fg", "#e8e2d4")
                        }
                    }

                    // Password field, styled like the bar's surfaces.
                    Rectangle {
                        id: inputCard
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 276
                        height: 46
                        radius: 0
                        color: root.withAlpha(root.getColor("bg", "#15130b"), 0.7)
                        border.width: 1
                        border.color: root.withAlpha(root.getColor("accent", "#dac76f"), 0.5)

                        TextField {
                            id: passwordInput
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            passwordCharacter: "●"
                            font.family: root.fontFamily
                            font.pixelSize: 13
                            font.letterSpacing: text === "" ? 0 : 4
                            color: root.getColor("fg", "#e8e2d4")
                            selectionColor: root.withAlpha(root.getColor("accent", "#dac76f"), 0.3)
                            placeholderText: "Enter password to unlock"
                            placeholderTextColor: root.withAlpha(root.getColor("muted", "#969080"), 0.9)
                            background: Item {}
                            focus: true
                            cursorVisible: true

                            onAccepted: root.tryUnlock(passwordInput.text)
                        }

                        Connections {
                            target: root
                            function onAuthSig() {
                                passwordInput.clear()
                                passwordInput.forceActiveFocus()
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: passwordInput.forceActiveFocus()
                        }
                    }

                    // Status line: wrong-password error, shown fast below the field.
                    // Kept inside the Column so the card's height reserves room for
                    // it (anchoring it to inputCard.bottom used to overflow the card
                    // and break the layout when it appeared).
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.failedText
                        horizontalAlignment: Text.AlignHCenter
                        font.family: root.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        color: "#ff6b6b"
                        opacity: 1
                    }
                }
            }

            // ---- Now-playing card: below the login card ----------------------
            // Mirrors the quickmenu's MediaPlayerRow style (album art, title
            // / artist, play-pause + next). Detached from the login card and
            // only shown while something is playing/paused.
            RectangularShadow {
                anchors.fill: mediaCard
                visible: mediaCard.visible
                radius: 0
                color: "#000000"
                blur: 0
                spread: 0
                offset: Qt.vector2d(8, 8)
            }

            Rectangle {
                id: mediaCard
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 28
                width: 320
                height: 61
                radius: 0
                color: root.getColor("bg", "#15130b")
                border.width: 1
                border.color: root.withAlpha(root.getColor("accent", "#dac76f"), 0.3)
                visible: root.mediaStatus !== "None"

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12

                        // Album art thumbnail.
                        Rectangle {
                            width: 36
                            height: 36
                            radius: 0
                            color: "transparent"
                            border.width: 1
                            border.color: root.withAlpha(root.getColor("accent", "#dac76f"), 0.3)

                            ClippingRectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: 0
                                color: "transparent"

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    source: root.mediaArtUrl
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    asynchronous: true
                                    cache: false
                                    visible: status === Image.Ready && root.mediaArtUrl !== ""
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰎇"
                                    font.family: root.fontFamily
                                    font.pixelSize: 18
                                    color: root.withAlpha(root.getColor("muted", "#969080"), 0.5)
                                    visible: root.mediaArtUrl === ""
                                }
                            }
                        }

                        // Track info.
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            width: parent.width - 134

                            Text {
                                text: root.mediaTitle || root.mediaName || "Unknown"
                                font.family: root.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: root.getColor("fg", "#e8e2d4")
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: root.mediaArtist || "Unknown Artist"
                                font.family: root.fontFamily
                                font.pixelSize: 10
                                color: root.withAlpha(root.getColor("muted", "#969080"), 0.9)
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        // Play / Pause.
                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            color: playMouse.hovered
                                ? root.withAlpha(root.getColor("accent", "#dac76f"), 0.14)
                                : "transparent"
                            border.width: playMouse.hovered ? 1 : 0
                            border.color: root.withAlpha(root.getColor("accent", "#dac76f"), 0.4)
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: root.mediaStatus === "Playing" ? "󰏤" : "󰐊"
                                font.family: root.fontFamily
                                font.pixelSize: 13
                                color: root.getColor("accent", "#dac76f")
                            }

                            MouseArea {
                                id: playMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    mediaPlayPauseProc.command = ["/home/oryza/.config/sway/scripts/media-control", "PlayPause"]
                                    mediaPlayPauseProc.startDetached()
                                }
                            }
                        }

                        // Next.
                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            color: nextMouse.hovered
                                ? root.withAlpha(root.getColor("accent", "#dac76f"), 0.14)
                                : "transparent"
                            border.width: nextMouse.hovered ? 1 : 0
                            border.color: root.withAlpha(root.getColor("accent", "#dac76f"), 0.4)
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "󰒭"
                                font.family: root.fontFamily
                                font.pixelSize: 13
                                color: root.getColor("accent", "#dac76f")
                            }

                            MouseArea {
                                id: nextMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    mediaNextProc.command = ["/home/oryza/.config/sway/scripts/media-control", "Next"]
                                    mediaNextProc.startDetached()
}
                }
            }
        }
    }
}
    }
}