import Quickshell
import Quickshell.I3
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "colors.js" as Colors
import "settings.js" as Settings
import "windows"
import "fox"
import "lonely"
import "nerv"
ShellRoot {
    id: root

    // ---- Theme helpers -------------------------------------------------
    // Colors are reactive properties (not the cached .pragma library), so
    // theme-switch can hot-reload them via IPC (applyColors) without a full
    // quickshell restart. Each getColor() call reads one of these properties;
    // QML tracks those reads, so any binding calling getColor re-evaluates
    // when the live palette is swapped.

    // my config dirs; QML won't expand $HOME so pull it from env
    readonly property string homeDir: Quickshell.env("HOME")
    property string qsBarDir: homeDir + "/.config/quickshell/bar"
    property string swayScriptsDir: homeDir + "/.config/sway/scripts"

    // Path to the generated palette. Kept in sync with theme-switch.
    readonly property string colorsPath: qsBarDir + "/colors.js"

    // Initial palette from colors.js (first-load import). applyColors() later
    // re-reads the file and moves these. Stored as hex strings (not `color`)
    // so the existing withAlpha()/mixHex() helpers keep receiving #rrggbb.
    property string colorBg: Colors.COLORS.bg
    property string colorFg: Colors.COLORS.fg
    property string colorAccent: Colors.COLORS.accent
    property string colorSecondary: Colors.COLORS.secondary
    property string colorSurfaceVariant: Colors.COLORS.surface_variant
    property string colorMuted: Colors.COLORS.muted

    // ---- Rice settings (visual tokens) ----------------------------------
    // Read from settings.js at load; the settings page edits these reactive
    // properties live and calls saveRiceSettings() to persist to sway + disk.

    property int borderWidth: Settings.SETTINGS.borderWidth
    readonly property bool borderEnabled: borderWidth > 0
    property int cornerRadius: Settings.SETTINGS.cornerRadius
    property string barSide: Settings.SETTINGS.barSide
    property string fontFamily: Settings.SETTINGS.fontFamily
    property bool barBorder: Settings.SETTINGS.barBorder
    property bool barShadow: Settings.SETTINGS.barShadow
    property bool quickMenuBorder: Settings.SETTINGS.quickMenuBorder
    property bool quickMenuShadow: Settings.SETTINGS.quickMenuShadow
    property bool osdBorder: Settings.SETTINGS.osdBorder
    property bool osdShadow: Settings.SETTINGS.osdShadow
    property string activeBar: Settings.SETTINGS.activeBar
    property bool barFullWidth: Settings.SETTINGS.barFullWidth
    property bool nightLight: Settings.SETTINGS.nightLight
    property int nightLightIntensity: Settings.SETTINGS.nightLightIntensity || 3
    property int noiseLevel: Settings.SETTINGS.noiseLevel

    // Corner radius applied to the bar / quick menu / OSD / notification faces.
    // Independent of the sway window border (corner_radius is per-window there).
    readonly property int frameRadius: cornerRadius

    FileView {
        id: settingsFile
        path: qsBarDir + "/settings.js"
        preload: true
        blockAllReads: true
        watchChanges: false
    }

    // Parse settings.js into the reactive properties. Callers are responsible
    // for the file being already reloaded (see pollRiceSettings).
    function parseRiceSettings(): void {
        var raw = settingsFile.text()
        function boolValue(key, current) {
            var m = new RegExp(key + ':[ \\t]*(true|false)').exec(raw)
            return m ? m[1] === "true" : current
        }
        function intValue(key, current) {
            var m = new RegExp(key + ':[ \\t]*(\\d+)').exec(raw)
            return m ? parseInt(m[1]) : current
        }
        function stringValue(key, current) {
            var m = new RegExp(key + ':[ \\t]*"([^"]*)"').exec(raw)
            return m ? m[1] : current
        }
        borderWidth = intValue("borderWidth", borderWidth)
        cornerRadius = intValue("cornerRadius", cornerRadius)
        barSide = stringValue("barSide", barSide)
        fontFamily = stringValue("fontFamily", fontFamily)
        barBorder = boolValue("barBorder", barBorder)
        barShadow = boolValue("barShadow", barShadow)
        quickMenuBorder = boolValue("quickMenuBorder", quickMenuBorder)
        quickMenuShadow = boolValue("quickMenuShadow", quickMenuShadow)
        osdBorder = boolValue("osdBorder", osdBorder)
        osdShadow = boolValue("osdShadow", osdShadow)
        barFullWidth = boolValue("barFullWidth", barFullWidth)
        activeBar = stringValue("activeBar", activeBar)
        nightLight = boolValue("nightLight", nightLight)
        noiseLevel = intValue("noiseLevel", noiseLevel)
        nightLightIntensity = intValue("nightLightIntensity", nightLightIntensity)
    }

    // Poll the on-disk settings.js so changes saved by the wallpaper-picker (a
    // separate process) reach this bar live. Cheap: only re-parses on change.
    property string riceHash: ""
    function pollRiceSettings(): void {
        settingsFile.reload()
        var t = settingsFile.text()
        if (t === riceHash) return
        riceHash = t
        parseRiceSettings()
    }

    Timer {
        interval: 400
        repeat: true
        running: true
        onTriggered: root.pollRiceSettings()
    }

    Process {
        id: riceSettingsProc
    }

    // Persist the current reactive tokens to sway + disk via the bridge script.
    function saveRiceSettings(): void {
        riceSettingsProc.command = ["bash", swayScriptsDir + "/rice-settings-apply",
            borderWidth + "", cornerRadius + "", barSide, fontFamily,
            barBorder + "", barShadow + "", quickMenuBorder + "", quickMenuShadow + "",
            osdBorder + "", osdShadow + "", barFullWidth + "", activeBar,
            nightLight + "", noiseLevel + "", nightLightIntensity + ""]
        riceSettingsProc.startDetached()
    }

    function getColor(key, fallback) {
        // Nerv bar override: pin every token to the NERV red-on-black scheme
        // (matching the bar) instead of the wallpaper palette, so the quick
        // menu / OSD / notifications share the nerv look.
        if (activeBar === "nerv") {
            switch (key) {
                case "bg": return "#0d0707"
                case "fg": return "#f2d2d2"
                case "accent": return "#9D0A12"
                case "secondary": return "#a00a0a"
                case "surface_variant": return "#2a1414"
                case "muted": return "#8a5a5a"
                default: return fallback
            }
        }
        switch (key) {
            case "bg": return colorBg
            case "fg": return colorFg
            case "accent": return colorAccent
            case "secondary": return colorSecondary
            case "surface_variant": return colorSurfaceVariant
            case "muted": return colorMuted
            default: return fallback
        }
    }

    // Parse a fresh palette from colors.js (avoids the .pragma library cache)
    // and push it into the reactive properties above.
    function applyColors(): void {
        colorsFile.reload()
        var raw = colorsFile.text()
        function hex(key, cur) {
            var m = new RegExp(key + ':\\s*"?(#[0-9a-fA-F]{6})').exec(raw)
            return m ? m[1] : cur
        }
        colorBg = hex("bg", colorBg)
        colorFg = hex("fg", colorFg)
        colorAccent = hex("accent", colorAccent)
        colorSecondary = hex("secondary", colorSecondary)
        colorSurfaceVariant = hex("surface_variant", colorSurfaceVariant)
        colorMuted = hex("muted", colorMuted)
    }

    FileView {
        id: colorsFile
        path: root.colorsPath
        preload: true
        blockAllReads: true
        watchChanges: false
    }

    function withAlpha(colorHex, alpha) {
        var r = parseInt(colorHex.substring(1, 3), 16)
        var g = parseInt(colorHex.substring(3, 5), 16)
        var b = parseInt(colorHex.substring(5, 7), 16)
        return Qt.rgba(r / 255, g / 255, b / 255, alpha)
    }

    // Relative-luminance of a #rrggbb string.
    function luminance(colorHex) {
        var r = parseInt(colorHex.substring(1, 3), 16) / 255
        var g = parseInt(colorHex.substring(3, 5), 16) / 255
        var b = parseInt(colorHex.substring(5, 7), 16) / 255
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    // Darkest of the live palette colors.
    readonly property string darkestColor: {
        var best = colorBg
        var cands = [colorBg, colorFg, colorAccent, colorSecondary, colorSurfaceVariant, colorMuted]
        for (var i = 1; i < cands.length; i++)
            if (luminance(cands[i]) < luminance(best)) best = cands[i]
        return best
    }

    // Blend two hex colors into an opaque color. amount is how much of the
    // second color (e.g. accent) is mixed into the first (e.g. bg).
    function mixHex(baseHex, accentHex, amount) {
        var r1 = parseInt(baseHex.substring(1, 3), 16)
        var g1 = parseInt(baseHex.substring(3, 5), 16)
        var b1 = parseInt(baseHex.substring(5, 7), 16)
        var r2 = parseInt(accentHex.substring(1, 3), 16)
        var g2 = parseInt(accentHex.substring(3, 5), 16)
        var b2 = parseInt(accentHex.substring(5, 7), 16)
        function h(n) {
            var s = Math.round(n).toString(16)
            return s.length < 2 ? "0" + s : s
        }
        return "#" + h(r1 + (r2 - r1) * amount) + h(g1 + (g2 - g1) * amount) + h(b1 + (b2 - b1) * amount)
    }

    // ---- System state --------------------------------------------------

    property string wifiName: ""
    property bool isWifiConnecting: false
    property bool isWifiHovered: false
    property bool bluetoothEnabled: false
    property string bluetoothDeviceName: ""
    property bool isBluetoothConnecting: false
    property bool isDndEnabled: false
    property bool isNightLightEnabled: Settings.SETTINGS.nightLight
    property int volume: -1
    property bool isVolumeMuted: false
    property bool isVolumeHovered: false
    property bool isVolumeDragging: false
    property int wheelAccum: 0
    property string dateText: ""
    property string timeText: ""
    // "22 aug 11:55" style timestamp.
    property string dateTimeText: ""
    property string windowTitle: ""
    property string mediaStatus: "None"
    property string mediaName: ""
    property string mediaTitle: ""
    property string mediaArtist: ""
    property string mediaArtUrl: ""
    property bool isClockHovered: false
    property int batteryLevel: -1
    property string batteryStatus: "Unknown"
    property bool isBatteryHovered: false
    property int brightnessLevel: -1
    property bool isQuickMenuOpen: false
    property bool isPowerPageOpen: false
    property bool isNotificationPageOpen: false
    property bool isWallpaperPageOpen: false
    property bool isClipboardPageOpen: false
    property bool isSettingsPageOpen: false
    onIsQuickMenuOpenChanged: if (!isQuickMenuOpen) root.closeAllPages()

    function closeAllPages() {
        isPowerPageOpen = false
        isNotificationPageOpen = false
        isWallpaperPageOpen = false
        isClipboardPageOpen = false
        isSettingsPageOpen = false
    }

    // ---- Notifications -------------------------------------------------

    NotificationServer {
        id: notificationServer
        keepOnReload: true
        // Advertise the full capability set so Chrome/Firefox/Zen use the OS
        // path instead of their in-app fallback (they require at least
        // "actions" + "body" from GetCapabilities).
        actionsSupported: true
        actionIconsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        onNotification: (notification) => {
            if (root.isDndEnabled) {
                notification.dismiss()
                return
            }
            notification.tracked = true
            notification.closed.connect(() => {
                // A closed notification only leaves the transient popup; the
                // quick-menu history keeps it until the user dismisses it.
                for (var p = 0; p < notificationPopupModel.count; p++) {
                    if (notificationPopupModel.get(p).notification === notification) {
                        notificationPopupModel.remove(p)
                        break
                    }
                }
            })
            var entry = {
                notification: notification,
                appName: notification.appName,
                summary: notification.summary,
                body: notification.body,
                image: notification.image,
                appIcon: notification.appIcon,
                timestamp: Date.now()
            }
            notificationListModel.insert(0, entry)
            notificationPopupModel.append(entry)
        }
    }

    ListModel { id: notificationListModel }
    ListModel { id: notificationPopupModel }

    function clearNotifications() {
        for (var i = notificationListModel.count - 1; i >= 0; i--) {
            var item = notificationListModel.get(i)
            if (item && item.notification) {
                try { item.notification.dismiss() } catch (e) {}
            }
            notificationListModel.remove(i)
        }
        notificationPopupModel.clear()
    }

    // ---- Bar geometry + workspaces -------------------------------------

    // Bar floats centered at 60% of the screen width (20% side margins).
    readonly property real barSideMargin: Quickshell.screens[0].width * 0.2

    // DPI-based UI scale. logicalPixelDensity is pixels-per-mm; convert to
    // logical dots-per-inch and gauge against the standard 96 DPI. Clamped so
    // tiny/low-DPI screens don't collapse and hi-DPI screens don't explode.
    // Every fixed pixel value multiplies by this so the UI flexes with the
    // display resolution instead of staying 1080p-sized.
    readonly property real uiScale: {
        var screen = Quickshell.screens[0]
        var dpi = (screen.logicalPixelDensity * 25.4) / 96
        return Math.max(0.7, Math.min(2.0, dpi))
    }
    // Distance from the screen edge to a tiled window's edge (= `gaps outer` +
    // `gaps inner`, read live from sway via pollGaps). The OSD/notification
    // panels align to a tiled window's left/right edges with this gap, so it is
    // reactive: if sway's gaps change, the panels stay aligned. Defaults to 35
    // (the classic outer 30 + inner 5) until the first poll succeeds.
    property int windowGap: 35
    // Icon center offsets from the bar's right edge (box padding + half icon),
    // used to position the hover tips above their icons.
    readonly property int wifiIconCenterFromBarRight: 18
    readonly property int volumeIconCenterFromBarRight: 46
    readonly property int batteryIconCenterFromBarRight: 74
    // Clock box center offset from the bar's left edge (12px left margin +
    // half of the 58px box).
    readonly property int clockCenterFromBarLeft: 41

    ListModel { id: workspaceModel }

    // Workspace indicators: active ws -> filled, ws with windows -> outlined.
    // Sway destroys empty workspaces, so the I3 model only holds workspaces
    // that are focused or contain windows.
    function updateWorkspaces() {
        var workspaces = I3.workspaces.values
        var list = []
        for (var i = 0; i < workspaces.length; i++) {
            var w = workspaces[i]
            if (w.num > 0)
                list.push({ id: w.num, active: w.active })
        }
        list.sort(function(a, b) { return a.id - b.id })
        workspaceModel.clear()
        for (var j = 0; j < list.length; j++)
            workspaceModel.append(list[j])
    }

    Connections {
        target: I3
        function onRawEvent(event) { root.updateWorkspaces() }
        function onFocusedWorkspaceChanged() { root.updateWorkspaces() }
    }

    // ---- Polling and toggles -------------------------------------------

    function pollWifi() {
        wifiNameProc.exec([swayScriptsDir + "/wifi-name"])
    }

    // Flip the wifi state optimistically, then re-poll so the icon/name catch
    // up once NetworkManager settles (re-enabling + reconnecting takes a moment).
    function toggleWifi() {
        var turningOn = root.wifiName === ""
        root.isWifiConnecting = turningOn
        wifiToggleProc.command = [swayScriptsDir + "/wifi-toggle"]
        wifiToggleProc.startDetached()
        root.wifiName = ""
        if (turningOn)
            wifiConnectTimeout.restart()
        wifiVerify.restart()
        wifiResync.restart()
    }

    function pollBluetooth() {
        bluetoothProc.exec([swayScriptsDir + "/bluetooth-status"])
    }

    // Flip bluetooth state optimistically, then re-poll once bluez settles.
    function toggleBluetooth() {
        var turningOn = !root.bluetoothEnabled
        root.isBluetoothConnecting = turningOn
        bluetoothToggleProc.command = [swayScriptsDir + "/bluetooth-toggle"]
        bluetoothToggleProc.startDetached()
        if (turningOn) {
            root.bluetoothEnabled = true
            bluetoothConnectTimeout.restart()
        } else {
            root.bluetoothEnabled = false
            root.bluetoothDeviceName = ""
        }
        bluetoothVerify.restart()
        bluetoothResync.restart()
    }

    function toggleDnd() {
        root.isDndEnabled = !root.isDndEnabled
    }

    function toggleNightLight() {
        root.isNightLightEnabled = !root.isNightLightEnabled
        root.nightLight = root.isNightLightEnabled
        // Persist + apply via the lightweight script (no sway reload), so
        // toggling doesn't reset gamma or re-render the wallpaper.
        var mode = root.isNightLightEnabled ? "on" : "off"
        nightLightProc.command = [swayScriptsDir + "/nightlight-apply", mode, root.nightLightIntensity + ""]
        nightLightProc.startDetached()
    }

    // Persist + apply a new intensity seamlessly without the full rice save.
    // Debounced so rapid slider input coalesces into a single apply.
    function setNightLightIntensity(v): void {
        root.nightLightIntensity = v
        nightLightDebounce.restart()
    }

    Timer {
        id: nightLightDebounce
        interval: 60
        onTriggered: {
            var mode = root.isNightLightEnabled ? "on" : "off"
            nightLightProc.command = [swayScriptsDir + "/nightlight-apply", mode, root.nightLightIntensity + ""]
            nightLightProc.startDetached()
        }
    }

    function setNoiseLevel(level) {
        root.noiseLevel = level
        root.saveRiceSettings()
    }

    function pollVolume() {
        volumeProc.exec([swayScriptsDir + "/volume-get"])
    }

    function updateClock() {
        var d = new Date()
        var months = ["jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"]
        root.dateText = d.getDate() + "-" + months[d.getMonth()] + "-" + String(d.getFullYear()).slice(-2)
        var h = d.getHours(), m = d.getMinutes()
        root.timeText = (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
        root.dateTimeText = d.getDate() + " " + months[d.getMonth()] + " " + root.timeText
    }

    function pollMedia() {
        mediaProc.exec([swayScriptsDir + "/now-playing"])
    }

    // Flip the icon optimistically for instant feedback, then resync with the
    // real player state. Polling right after the toggle returns stale data, so
    // skip the immediate poll and let the short re-poll timers do the work.
    function toggleMediaPlay() {
        root.mediaStatus = root.mediaStatus === "Playing" ? "Paused" : "Playing"
        mediaToggleProc.command = [swayScriptsDir + "/media-control", "PlayPause"]
        mediaToggleProc.startDetached()
        mediaVerify.restart()
        mediaResync.restart()
    }

    function pollBattery() {
        batteryProc.exec([swayScriptsDir + "/battery-get"])
    }

    function pollBrightness() {
        brightnessProc.exec(["bash", "-c", "echo $(($(brightnessctl get) * 100 / $(brightnessctl max)))"])
    }

    function pollWindowTitle() {
        windowTitleProc.exec([swayScriptsDir + "/window-title"])
    }

    // Read sway's real gaps (outer + inner) so the OSD/notification panels keep
    // aligning to a tiled window's edge if the gaps change. sway's GET_CONFIG
    // IPC returns the config as text; grep the `gaps inner` / `gaps outer`
    // directives and sum them (defaults to 5/30 if absent).
    function pollGaps() {
        gapsProc.exec(["bash", "-c",
            "swaymsg -t get_config -r 2>/dev/null | python3 -c 'import json,sys,re;c=json.load(sys.stdin)[\"config\"];i=re.search(r\"gaps inner\\s+(\\d+)\",c);o=re.search(r\"gaps outer\\s+(\\d+)\",c);print((int(i.group(1)) if i else 5)+(int(o.group(1)) if o else 30))'"])
    }

    function setBrightness(val) {
        brightnessSetProc.command = ["brightnessctl", "set", val + "%"]
        brightnessSetProc.startDetached()
        root.brightnessLevel = val
    }

    // wpctl set-volume does not unmute a muted sink, so unmute first —
    // otherwise raising the level stays silent.
    function setVolume(val) {
        volumeStepProc.command = ["sh", "-c",
            "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ " + (val / 100)]
        volumeStepProc.startDetached()
        volumeRefreshTimer.restart()
    }

    // ---- Timers ---------------------------------------------------------

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updateClock()
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: root.pollWindowTitle()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: { root.pollWifi(); root.pollBattery() }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.pollVolume()
    }

    Timer {
        id: mediaTimer
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.pollMedia()
    }

    // Re-poll shortly after a media action so the icon reflects the real state
    // quickly instead of waiting for the next periodic tick. The player (e.g.
    // Firefox) usually updates its MPRIS PlaybackStatus a few hundred ms after
    // a PlayPause method call returns, so a second slower poll is a safety net.
    Timer {
        id: mediaVerify
        interval: 200
        onTriggered: root.pollMedia()
    }

    Timer {
        id: mediaResync
        interval: 1200
        onTriggered: root.pollMedia()
    }

    // Re-poll shortly after a wifi toggle to reflect the new radio state.
    Timer {
        id: wifiVerify
        interval: 800
        onTriggered: root.pollWifi()
    }

    Timer {
        id: wifiResync
        interval: 2500
        onTriggered: root.pollWifi()
    }

    // Safety net: stop showing "Connecting…" if NM never manages to reconnect.
    Timer {
        id: wifiConnectTimeout
        interval: 10000
        onTriggered: root.isWifiConnecting = false
    }

    // Re-poll shortly after a bluetooth toggle to reflect the new state.
    Timer {
        id: bluetoothVerify
        interval: 1500
        onTriggered: root.pollBluetooth()
    }

    Timer {
        id: bluetoothResync
        interval: 3500
        onTriggered: root.pollBluetooth()
    }

    // Safety net: stop showing "Connecting…" if bluez never reconnects.
    Timer {
        id: bluetoothConnectTimeout
        interval: 12000
        onTriggered: root.isBluetoothConnecting = false
    }

    Timer {
        id: volumeRefreshTimer
        interval: 150
        onTriggered: root.pollVolume()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.pollBrightness()
    }

    // Gaps rarely change, so poll lazily (startup + every 10s) to keep the
    // OSD/notification alignment correct without much overhead.
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.pollGaps()
    }

    // Coalesce wheel bursts into a single volume step.
    Timer {
        id: volumeCommitTimer
        interval: 40
        onTriggered: {
            var notches = Math.abs(Math.floor(root.wheelAccum / 120))
            if (notches <= 0) { root.wheelAccum = 0; return }
            var sign = root.wheelAccum > 0 ? 1 : -1
            root.wheelAccum = 0
            var levelArg
            if (root.volume >= 0) {
                var target = Math.max(0, Math.min(100, root.volume + sign * 5 * notches))
                levelArg = (target / 100).toString()
            } else {
                levelArg = sign > 0 ? "5%+" : "5%-"
            }
            volumeStepProc.command = ["sh", "-c",
                "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ " + levelArg]
            volumeStepProc.startDetached()
            volumeRefreshTimer.restart()
        }
    }

    // ---- Processes ------------------------------------------------------

    Process {
        id: batteryProc
        stdout: StdioCollector { id: batteryOutput; waitForEnd: true }
        onExited: (code, status) => {
            var out = batteryOutput.text.trim()
            var parts = out.split(":")
            if (parts.length >= 2) {
                root.batteryStatus = parts[0]
                root.batteryLevel = parseInt(parts[1]) || 0
            }
        }
    }

    Process {
        id: powerMenuProc
    }

    Process {
        id: windowTitleProc
        stdout: StdioCollector { id: windowTitleOutput; waitForEnd: true }
        onExited: (code, status) => {
            root.windowTitle = windowTitleOutput.text.trim()
        }
    }

    Process {
        id: wifiNameProc
        stdout: StdioCollector { id: wifiNameOutput; waitForEnd: true }
        onExited: (code, status) => {
            root.wifiName = wifiNameOutput.text.trim()
            if (root.wifiName !== "") {
                root.isWifiConnecting = false
                wifiConnectTimeout.stop()
            }
        }
    }

    Process {
        id: wifiToggleProc
    }

    Process {
        id: bluetoothProc
        stdout: StdioCollector { id: bluetoothOutput; waitForEnd: true }
        onExited: (code, status) => {
            var out = bluetoothOutput.text.trim()
            var parts = out.split(":")
            root.bluetoothEnabled = parts[0] === "on"
            root.bluetoothDeviceName = parts.length > 1 ? parts.slice(1).join(":") : ""
            if (root.bluetoothEnabled && root.bluetoothDeviceName !== "") {
                root.isBluetoothConnecting = false
                bluetoothConnectTimeout.stop()
            }
        }
    }

    Process {
        id: bluetoothToggleProc
    }

    Process {
        id: nightLightProc
    }

    Process {
        id: volumeProc
        stdout: StdioCollector { id: volumeOutput; waitForEnd: true }
        onExited: (code, status) => {
            if (root.isVolumeDragging) return
            var out = volumeOutput.text.trim()
            root.isVolumeMuted = out.charAt(0) === "M"
            root.volume = root.isVolumeMuted ? (parseInt(out.substring(1)) || 0) : (parseInt(out) || 0)
        }
    }

    Process {
        id: volumeStepProc
    }

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

    Process {
        id: mediaToggleProc
    }

    Process {
        id: mediaNextProc
    }

    Process {
        id: brightnessProc
        stdout: StdioCollector { id: brightnessOutput; waitForEnd: true }
        onExited: (code, status) => {
            var out = brightnessOutput.text.trim()
            root.brightnessLevel = parseInt(out) || 0
        }
    }

    Process {
        id: brightnessSetProc
    }

    Process {
        id: gapsProc
        stdout: StdioCollector { id: gapsOutput; waitForEnd: true }
        onExited: (code, status) => {
            var v = parseInt(gapsOutput.text.trim())
            if (!isNaN(v) && v > 0) root.windowGap = v
        }
    }

    // ---- Windows --------------------------------------------------------

    // Only one bar is ever shown. A Loader (instead of two PanelWindows whose
    // `visible` we flip) guarantees a single layer surface exists, so the
    // hidden bar can never overlap or grab the exclusive zone of the shown one.
    Component { id: foxBarComp; BarWindow {} }
    Component { id: lonelyBarComp; LonelyBar {} }
    Component { id: nervBarComp; NervBar {} }

    // Full-screen NERV backdrop (black + red rounded frame). Shown only while
    // the nerv bar is active; sits behind windows so clicks pass through.
    NervFrame {}

    Loader {
        id: barLoader
        sourceComponent: root.activeBar === "lonely" ? lonelyBarComp
                      : root.activeBar === "nerv" ? nervBarComp
                      : foxBarComp
        property alias bar: barLoader.item
    }

    HoverTip {
        id: wifiTip
        anchoredRight: true
        visible: root.isWifiHovered && root.wifiName !== ""
        horizontalMargin: root.barSideMargin + root.wifiIconCenterFromBarRight - wifiTip.implicitWidth / 2

        Text {
            text: root.wifiName
            font.family: root.fontFamily
            font.pixelSize: 12 * root.uiScale
            color: root.getColor("fg", "#f0dfd8")
        }
    }

    HoverTip {
        id: volumeTip
        anchoredRight: true
        visible: root.isVolumeHovered
        horizontalMargin: root.barSideMargin + root.volumeIconCenterFromBarRight - volumeTip.implicitWidth / 2

        Text {
            text: root.isVolumeMuted ? "muted" : (root.volume < 0 ? "--" : root.volume + "%")
            font.family: root.fontFamily
            font.pixelSize: 12 * root.uiScale
            color: root.isVolumeMuted
                ? root.withAlpha(root.getColor("muted", "#a08d85"), 0.85)
                : root.getColor("fg", "#f0dfd8")
        }
    }

    HoverTip {
        id: clockTip
        anchoredLeft: true
        visible: root.isClockHovered
        horizontalMargin: root.barSideMargin + root.clockCenterFromBarLeft - clockTip.implicitWidth / 2
        horizontalPadding: 28
        verticalPadding: 14

        Row {
            spacing: 10

            Text {
                text: root.dateText
                font.family: root.fontFamily
                font.pixelSize: 12 * root.uiScale
                font.bold: true
                color: root.getColor("muted", "#a08d85")
            }

            Text {
                text: root.timeText
                font.family: root.fontFamily
                font.pixelSize: 12 * root.uiScale
                color: root.getColor("fg", "#f0dfd8")
            }
        }
    }

    HoverTip {
        id: batteryTip
        anchoredRight: true
        visible: root.isBatteryHovered && root.batteryLevel >= 0
        horizontalMargin: root.barSideMargin + root.batteryIconCenterFromBarRight - batteryTip.implicitWidth / 2

        Row {
            spacing: 8

            Text {
                text: root.batteryLevel + "%"
                font.family: root.fontFamily
                font.pixelSize: 12 * root.uiScale
                font.bold: true
                color: (root.batteryStatus !== "Charging" && root.batteryLevel <= 15)
                    ? "#ff6b6b"
                    : root.getColor("fg", "#f0dfd8")
            }

            Text {
                visible: root.batteryStatus === "Charging" || root.batteryStatus === "Full"
                text: root.batteryStatus === "Charging" ? "charging" : "full"
                font.family: root.fontFamily
                font.pixelSize: 11 * root.uiScale
                color: root.batteryStatus === "Charging"
                    ? root.getColor("accent", "#ffb691")
                    : root.withAlpha(root.getColor("muted", "#a08d85"), 0.85)
            }
        }
    }

    QuickMenu {
        id: quickMenu
    }

    // Nerv-themed replacement for the quick menu.
    NervControlCenter {}

    NotificationPopup { cardWidth: osdWindow.cardWidth }

    NoiseOverlay {}

    OsdWindow { id: osdWindow }

    // ---- IPC (external control via `quickshell ipc call ...`) -----------

    // Open the quick menu straight to one page (e.g. Super+M -> power).
    // Toggling the same page again closes the menu.
    function openQuickMenuPage(pageName): void {
        var alreadyOpen = root["is" + pageName + "PageOpen"]
        root.closeAllPages()
        if (root.isQuickMenuOpen && alreadyOpen) {
            root.isQuickMenuOpen = false
            return
        }
        root["is" + pageName + "PageOpen"] = true
        root.isQuickMenuOpen = true
    }

    // Toggle the bar's visibility from a sway keybind (Super+B). Closes the
    // quick menu too so it can't float orphaned above a hidden bar.
    IpcHandler {
        target: "bar"
        function toggleBar(): void {
            var b = barLoader.item
            if (b.visible) {
                root.isQuickMenuOpen = false
            }
            b.visible = !b.visible
        }

        function openPowerMenu(): void { root.openQuickMenuPage("Power") }
        function openNotifications(): void { root.openQuickMenuPage("Notification") }
        function openClipboard(): void { root.openQuickMenuPage("Clipboard") }
        function openSettings(): void { root.openQuickMenuPage("Settings") }

        function setBar(mode): void {
            if (["fox", "lonely", "nerv"].indexOf(mode) === -1) return
            root.activeBar = mode
            root.saveRiceSettings()
        }

        // Hot-reload the palette from colors.js (called by theme-switch after
        // it regenerates the file) — updates the bar's colors in place instead
        // of restarting the whole quickshell process.
        function applyColors(): void {
            root.applyColors()
        }

        // Re-read settings.js from disk (called by rice-settings-apply after it
        // rewrites the file) so the bar + quick menu reflect a setting change
        // immediately instead of waiting for the next poll tick.
        function reloadSettings(): void {
            root.pollRiceSettings()
        }
    }

    Component.onCompleted: {
        root.pollWifi()
        root.pollVolume()
        root.pollBattery()
        root.pollBrightness()
        root.pollGaps()
        root.updateWorkspaces()
        root.updateClock()
        root.pollMedia()
        root.pollBluetooth()
        if (root.isNightLightEnabled) {
            nightLightProc.command = [swayScriptsDir + "/nightlight-toggle", "on", root.nightLightIntensity + ""]
            nightLightProc.startDetached()
        }
    }
}
