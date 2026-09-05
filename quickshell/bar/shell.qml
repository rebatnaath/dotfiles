import Quickshell
import Quickshell.I3
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "colors.js" as Colors
import "windows"
import "fox"
import "lonely"
ShellRoot {
    id: root

    // ---- Theme helpers -------------------------------------------------

    readonly property string homeDir: Quickshell.env("HOME")
    property string qsBarDir: homeDir + "/.config/quickshell/bar"
    property string swayScriptsDir: homeDir + "/.config/sway/scripts"

    readonly property string colorsPath: qsBarDir + "/colors.js"

    // palette from colors.js, reloaded by applyColors()
    property string colorBg: Colors.COLORS.bg
    property string colorFg: Colors.COLORS.fg
    property string colorAccent: Colors.COLORS.accent
    property string colorSecondary: Colors.COLORS.secondary
    property string colorSurfaceVariant: Colors.COLORS.surface_variant
    property string colorMuted: Colors.COLORS.muted

    // ---- Bar visual properties (synced from settings.js) ----------------

    property int borderWidth: 4
    readonly property bool borderEnabled: borderWidth > 0
    property int cornerRadius: 8
    property int innerRadius: 4
    property string barSide: "bottom"
    property string fontFamily: "GeistMono NFM"
    property bool barBorder: true
    property bool barShadow: true
    property bool quickMenuBorder: true
    property bool quickMenuShadow: true
    property bool osdBorder: true
    property bool osdShadow: true
    property string activeBar: "fox"
    property bool barFullWidth: false
    property bool nightLight: false
    property int nightLightIntensity: 3
    property int noiseLevel: 0
    property bool isCaffeineEnabled: false

    readonly property int frameRadius: cornerRadius

    FileView {
        id: settingsFile
        path: qsBarDir + "/settings.js"
        preload: true
        blockAllReads: true
        watchChanges: true
        onFileChanged: settingsFile.reload()
        onTextChanged: root.parseRiceSettings()
    }

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
        innerRadius = intValue("innerRadius", innerRadius)
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

    Process {
        id: nightLightApplyProc
        onExited: (code, status) => {
            if (code !== 0) console.warn("[bar] nightlight-apply failed:", code)
        }
    }

    Process {
        id: nightLightStartupProc
        onExited: (code, status) => {
            if (code !== 0) console.warn("[bar] nightlight-toggle startup failed:", code)
        }
    }

    Process {
        id: noiseApplyProc
        onExited: (code, status) => {
            if (code !== 0) console.warn("[bar] noise-apply failed:", code)
        }
    }

    function getColor(key, fallback) {
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

    // reload palette from colors.js
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
        watchChanges: true
        onFileChanged: colorsFile.reload()
        onTextChanged: root.applyColors()
    }

    function withAlpha(colorHex, alpha) {
        if (!colorHex || colorHex.length < 7) return Qt.rgba(0, 0, 0, alpha)
        var r = parseInt(colorHex.substring(1, 3), 16)
        var g = parseInt(colorHex.substring(3, 5), 16)
        var b = parseInt(colorHex.substring(5, 7), 16)
        return Qt.rgba(r / 255, g / 255, b / 255, alpha)
    }

    // relative luminance of #rrggbb
    function luminance(colorHex) {
        var r = parseInt(colorHex.substring(1, 3), 16) / 255
        var g = parseInt(colorHex.substring(3, 5), 16) / 255
        var b = parseInt(colorHex.substring(5, 7), 16) / 255
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    // blend two hex colors
    function mixHex(baseHex, accentHex, amount) {
        var r1 = parseInt(baseHex.substring(1, 3), 16)
        var g1 = parseInt(baseHex.substring(3, 5), 16)
        var b1 = parseInt(baseHex.substring(5, 7), 16)
        var r2 = parseInt(accentHex.substring(1, 3), 16)
        var g2 = parseInt(accentHex.substring(3, 5), 16)
        var b2 = parseInt(accentHex.substring(5, 7), 16)
        function h(n) {
            var v = Math.max(0, Math.min(255, Math.round(n)))
            var s = v.toString(16)
            return s.length < 2 ? "0" + s : s
        }
        return "#" + h(r1 + (r2 - r1) * amount) + h(g1 + (g2 - g1) * amount) + h(b1 + (b2 - b1) * amount)
    }

    // ---- System state --------------------------------------------------

    property string wifiName: ""
    property bool wifiEnabled: false
    property bool isWifiConnecting: false
    property bool bluetoothEnabled: false
    property string bluetoothDeviceName: ""
    property bool isBluetoothConnecting: false
    property bool isDndEnabled: false
    readonly property bool isNightLightEnabled: nightLight
    property int volume: -1
    property bool isVolumeMuted: false
    property bool isVolumeDragging: false
    // Accumulated scroll delta for volume control. Clamped to [-600, 600]
    // in BottomSection so max 5 notches (25% volume) per debounce cycle.
    property int wheelAccum: 0
    property string dateText: ""
    property string timeText: ""
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
    property int brightnessLevel: -1
    property bool isQuickMenuOpen: false
    property bool isPowerPageOpen: false
    property bool isNotificationPageOpen: false
    property bool isClipboardPageOpen: false
    onIsQuickMenuOpenChanged: if (!isQuickMenuOpen) root.closeAllPages()

    function closeAllPages() {
        isPowerPageOpen = false
        isNotificationPageOpen = false
        isClipboardPageOpen = false
    }

    // ---- Notifications -------------------------------------------------

    NotificationServer {
        id: notificationServer
        keepOnReload: true
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

    // TODO: Multi-monitor support — currently pinned to first screen.
    // Quickshell doesn't expose "which screen is this window on" from QML,
    // so we default to screens[0]. To support multi-monitor, the bar would
    // need to be launched per-output with a screen identifier.
    readonly property real barSideMargin: Quickshell.screens[0].width * 0.2

    property real barFaceHeight: 46 * root.uiScale

    readonly property real uiScale: {
        var screen = Quickshell.screens[0]
        // logicalPixelDensity may be undefined on some Wayland compositors
        var density = screen.logicalPixelDensity || (screen.height / (screen.height / 96))
        var dpi = (density * 25.4) / 96
        return Math.max(0.7, Math.min(2.0, dpi))
    }
    // sway gaps (outer + inner), polled from sway
    property int windowGap: 35
    readonly property int clockCenterFromBarLeft: 41

    ListModel { id: workspaceModel }

    // rebuild workspace list from i3
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
    }

    // Battery level is also monitored by sway/scripts/battery-notify (started
    // from sway config) which fires low-battery alerts. The bar only displays
    // the level; the alert daemon is independent.

    // ---- Polling and toggles -------------------------------------------

    function pollWifi() {
        wifiNameProc.exec([swayScriptsDir + "/wifi-name"])
    }

    function toggleWifi() {
        var turningOn = root.wifiName === ""
        root.isWifiConnecting = turningOn
        wifiToggleProc.command = [swayScriptsDir + "/wifi-toggle"]
        wifiToggleProc.startDetached()
        root.wifiName = ""
        if (turningOn) {
            root.wifiEnabled = true
            wifiConnectTimeout.restart()
        } else {
            root.wifiEnabled = false
        }
        wifiVerify.restart()
        wifiResync.restart()
    }

    function pollBluetooth() {
        bluetoothProc.exec([swayScriptsDir + "/bluetooth-status"])
    }

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
        root.nightLight = !root.nightLight
        nightLightApplyProc.command = ["bash", swayScriptsDir + "/nightlight-apply",
            root.nightLight ? "on" : "off", root.nightLightIntensity + ""]
        nightLightApplyProc.running = true
    }

    function toggleCaffeine() {
        root.isCaffeineEnabled = !root.isCaffeineEnabled
        caffeineProc.command = ["bash", "-c", root.isCaffeineEnabled
            ? "touch $HOME/.cache/caffeine-active; pkill swayidle 2>/dev/null || true"
            : "rm -f $HOME/.cache/caffeine-active; swayidle -w timeout 300 '$HOME/.config/sway/scripts/lock.sh' timeout 600 'swaymsg \"output * dpms off\"' resume 'swaymsg \"output * dpms on\"' before-sleep '$HOME/.config/sway/scripts/lock.sh' &"]
        caffeineProc.startDetached()
    }

    function setNightLightIntensity(v): void {
        root.nightLightIntensity = v
        // auto-enable night light when intensity > 0
        if (v > 0 && !root.nightLight) {
            root.nightLight = true
        } else if (v === 0 && root.nightLight) {
            root.nightLight = false
        }
        nightLightApplyProc.command = ["bash", swayScriptsDir + "/nightlight-apply",
            root.nightLight ? "on" : "off", v + ""]
        nightLightApplyProc.running = true
    }

    function setNoiseLevel(level) {
        root.noiseLevel = level
        noiseApplyProc.command = ["bash", swayScriptsDir + "/noise-apply", level + ""]
        noiseApplyProc.startDetached()
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

    // read sway gaps for OSD alignment
    function pollGaps() {
        gapsProc.exec(["bash", "-c",
            "swaymsg -t get_config -r 2>/dev/null | python3 -c 'import json,sys,re;c=json.load(sys.stdin)[\"config\"];i=re.search(r\"gaps inner\\s+(\\d+)\",c);o=re.search(r\"gaps outer\\s+(\\d+)\",c);print((int(i.group(1)) if i else 5)+(int(o.group(1)) if o else 30))'"])
    }

    function setBrightness(val) {
        brightnessSetProc.command = ["brightnessctl", "set", val + "%"]
        brightnessSetProc.startDetached()
        root.brightnessLevel = val
    }

    // unmute before setting volume
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

    // re-poll after wifi toggle
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

    // timeout if wifi never reconnects
    Timer {
        id: wifiConnectTimeout
        interval: 10000
        onTriggered: root.isWifiConnecting = false
    }

    // re-poll after bluetooth toggle
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

    // timeout if bluetooth never reconnects
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

    // poll gaps every 10s
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.pollGaps()
    }

    // coalesce wheel bursts into single volume step
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
        onExited: (code, status) => {
            if (code !== 0) console.warn("[bar] power-menu action failed:", code)
        }
    }

    Process {
        id: caffeineProc
        onExited: (code, status) => {
            if (code !== 0) console.warn("[bar] caffeine toggle failed:", code)
        }
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
            root.wifiEnabled = root.wifiName !== ""
            if (root.wifiName !== "") {
                root.isWifiConnecting = false
                wifiConnectTimeout.stop()
            }
        }
    }

    Process {
        id: wifiToggleProc
        onExited: (code, status) => {
            if (code !== 0) console.warn("[bar] wifi-toggle failed:", code)
        }
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
        onExited: (code, status) => {
            if (code !== 0) console.warn("[bar] bluetooth-toggle failed:", code)
        }
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
        onExited: (code, status) => {
            if (code !== 0) console.warn("[bar] volume-step failed:", code)
        }
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
        onExited: (code, status) => {
            if (code !== 0) console.warn("[bar] media-toggle failed:", code)
        }
    }

    Process {
        id: mediaNextProc
        onExited: (code, status) => {
            if (code !== 0) root.pollMedia()
        }
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
        onExited: (code, status) => {
            if (code !== 0) console.warn("[bar] brightness-set failed:", code)
        }
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

    Component { id: foxBarComp; BarWindow {} }
    Component { id: lonelyBarComp; LonelyBar {} }

    Loader {
        id: barLoader
        sourceComponent: root.activeBar === "lonely" ? lonelyBarComp
                      : foxBarComp
        property alias bar: barLoader.item
        // re-anchor on bar position change
        Connections {
            target: root
            function onBarSideChanged() {
                barLoader.active = false
                Qt.callLater(function() { barLoader.active = true })
            }
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

    Loader {
        id: quickMenuLoader
        active: true
        sourceComponent: Component {
            QuickMenu {}
        }
        // re-anchor on bar position change
        Connections {
            target: root
            function onBarSideChanged() {
                quickMenuLoader.active = false
                Qt.callLater(function() { quickMenuLoader.active = true })
            }
        }
    }

    NotificationPopup { cardWidth: osdWindow.cardWidth }

    NoiseOverlay {}

    OsdWindow { id: osdWindow }

    // ---- IPC -----------------------------------------------------------

    // open quick menu to a specific page
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

    // toggle bar visibility (Super+B)
    IpcHandler {
        target: "bar"
        function toggleBar(): void {
            var b = barLoader.item
            if (!b) return
            if (b.visible) {
                root.isQuickMenuOpen = false
            }
            b.visible = !b.visible
        }

        function openPowerMenu(): void { root.openQuickMenuPage("Power") }
        function openNotifications(): void { root.openQuickMenuPage("Notification") }
        function openClipboard(): void { root.openQuickMenuPage("Clipboard") }

        // reload palette from colors.js
        function applyColors(): void {
            root.applyColors()
        }
    }

    Component.onCompleted: {
        root.parseRiceSettings()
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
            nightLightStartupProc.command = [swayScriptsDir + "/nightlight-toggle", "on", root.nightLightIntensity + ""]
            nightLightStartupProc.startDetached()
        }
    }
}
