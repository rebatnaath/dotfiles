import Quickshell
import Quickshell.I3
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "colors.js" as Colors
import "settings.js" as Settings
import "windows"
import "fox"
import "cat"
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

    // ---- Rice settings ------------------------------------------------

    property int borderWidth: Settings.SETTINGS.borderWidth
    readonly property bool borderEnabled: borderWidth > 0
    property int cornerRadius: Settings.SETTINGS.cornerRadius
    property int innerRadius: Settings.SETTINGS.innerRadius !== undefined ? Settings.SETTINGS.innerRadius : 4
    property string barSide: Settings.SETTINGS.barSide
    property string fontFamily: Settings.SETTINGS.fontFamily
    property bool barBorder: Settings.SETTINGS.barBorder
    property bool barShadow: Settings.SETTINGS.barShadow
    property bool quickMenuBorder: Settings.SETTINGS.quickMenuBorder
    property bool quickMenuShadow: Settings.SETTINGS.quickMenuShadow
    property bool osdBorder: Settings.SETTINGS.osdBorder
    property bool osdShadow: Settings.SETTINGS.osdShadow
    property bool notificationBorder: Settings.SETTINGS.notificationBorder !== undefined ? Settings.SETTINGS.notificationBorder : osdBorder
    property bool notificationShadow: Settings.SETTINGS.notificationShadow !== undefined ? Settings.SETTINGS.notificationShadow : osdShadow
    property int notificationCornerRadius: Settings.SETTINGS.notificationCornerRadius !== undefined ? Settings.SETTINGS.notificationCornerRadius : cornerRadius
    property string activeBar: Settings.SETTINGS.activeBar
    property bool barFullWidth: Settings.SETTINGS.barFullWidth
    property bool nightLight: Settings.SETTINGS.nightLight
    property int nightLightIntensity: Settings.SETTINGS.nightLightIntensity !== undefined ? Settings.SETTINGS.nightLightIntensity : 3
    property int noiseLevel: Settings.SETTINGS.noiseLevel
    property bool isCaffeineEnabled: Settings.SETTINGS.caffeine !== undefined ? Settings.SETTINGS.caffeine : false

    // per-component decoration knobs
    property int barBorderWidth: Settings.SETTINGS.barBorderWidth !== undefined ? Settings.SETTINGS.barBorderWidth : 4
    property int barCornerRadius: Settings.SETTINGS.barCornerRadius !== undefined ? Settings.SETTINGS.barCornerRadius : cornerRadius
    property int barInnerRadius: Settings.SETTINGS.barInnerRadius !== undefined ? Settings.SETTINGS.barInnerRadius : innerRadius
    property int quickMenuBorderWidth: Settings.SETTINGS.quickMenuBorderWidth !== undefined ? Settings.SETTINGS.quickMenuBorderWidth : 1
    property int quickMenuCornerRadius: Settings.SETTINGS.quickMenuCornerRadius !== undefined ? Settings.SETTINGS.quickMenuCornerRadius : cornerRadius
    property int quickMenuInnerRadius: Settings.SETTINGS.quickMenuInnerRadius !== undefined ? Settings.SETTINGS.quickMenuInnerRadius : innerRadius
    property string osdPosition: Settings.SETTINGS.osdPosition !== undefined ? Settings.SETTINGS.osdPosition : "top-right"
    property int osdCornerRadius: Settings.SETTINGS.osdCornerRadius !== undefined ? Settings.SETTINGS.osdCornerRadius : cornerRadius
    property int osdMargin: Settings.SETTINGS.osdMargin !== undefined ? Settings.SETTINGS.osdMargin : 35

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

    // parse settings.js into reactive properties
    property bool nightLightDirty: false
    property bool nightLightIntensityDirty: false
    property bool caffeineDirty: false
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
        notificationBorder = boolValue("notificationBorder", notificationBorder)
        notificationShadow = boolValue("notificationShadow", notificationShadow)
        notificationCornerRadius = intValue("notificationCornerRadius", notificationCornerRadius)
        barFullWidth = boolValue("barFullWidth", barFullWidth)
        activeBar = stringValue("activeBar", activeBar)
        if (!nightLightDirty) nightLight = boolValue("nightLight", nightLight)
        noiseLevel = intValue("noiseLevel", noiseLevel)
        if (!nightLightIntensityDirty) nightLightIntensity = intValue("nightLightIntensity", nightLightIntensity)
        if (!caffeineDirty) isCaffeineEnabled = boolValue("caffeine", isCaffeineEnabled)
        barBorderWidth = intValue("barBorderWidth", barBorderWidth)
        barCornerRadius = intValue("barCornerRadius", barCornerRadius)
        barInnerRadius = intValue("barInnerRadius", barInnerRadius)
        quickMenuBorderWidth = intValue("quickMenuBorderWidth", quickMenuBorderWidth)
        quickMenuCornerRadius = intValue("quickMenuCornerRadius", quickMenuCornerRadius)
        quickMenuInnerRadius = intValue("quickMenuInnerRadius", quickMenuInnerRadius)
        osdPosition = stringValue("osdPosition", osdPosition)
        osdCornerRadius = intValue("osdCornerRadius", osdCornerRadius)
        osdMargin = intValue("osdMargin", osdMargin)
        foxStatusBar = boolValue("foxStatusBar", foxStatusBar)
    }

    Process {
        id: riceSettingsProc
    }

    Process {
        id: nightLightApplyProc
    }

    Process {
        id: nightLightStartupProc
    }

    Process {
        id: noiseApplyProc
    }

    Process {
        id: settingsWriteProc
        onExited: (code, status) => {
            if (code === 0) {
                riceSettingsProc.command = ["bash", swayScriptsDir + "/rice-settings-apply"]
                riceSettingsProc.running = true
            }
        }
    }

    // save settings to sway + disk
    function saveRiceSettings(): void {
        // escape a value for safe embedding in a JS string literal
        function jsStr(s) {
            if (typeof s !== "string") s = String(s)
            return s.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n").replace(/\r/g, "\\r")
        }
        // 1) write settings.js via bash (use tee for reliability)
        var js = ".pragma library\nvar SETTINGS = {\n" +
            "    borderWidth: " + borderWidth + ",\n" +
            "    cornerRadius: " + cornerRadius + ",\n" +
            "    innerRadius: " + innerRadius + ",\n" +
            '    barSide: "' + jsStr(barSide) + '",\n' +
            '    fontFamily: "' + jsStr(fontFamily) + '",\n' +
            "    barBorder: " + barBorder + ",\n" +
            "    barShadow: " + barShadow + ",\n" +
            "    quickMenuBorder: " + quickMenuBorder + ",\n" +
            "    quickMenuShadow: " + quickMenuShadow + ",\n" +
            "    osdBorder: " + osdBorder + ",\n" +
            "    osdShadow: " + osdShadow + ",\n" +
            "    notificationBorder: " + notificationBorder + ",\n" +
            "    notificationShadow: " + notificationShadow + ",\n" +
            "    notificationCornerRadius: " + notificationCornerRadius + ",\n" +
            "    barFullWidth: " + barFullWidth + ",\n" +
            '    activeBar: "' + jsStr(activeBar) + '",\n' +
            "    nightLight: " + nightLight + ",\n" +
            "    nightLightIntensity: " + nightLightIntensity + ",\n" +
            "    noiseLevel: " + noiseLevel + ",\n" +
            "    caffeine: " + isCaffeineEnabled + ",\n" +
            "    barBorderWidth: " + barBorderWidth + ",\n" +
            "    barCornerRadius: " + barCornerRadius + ",\n" +
            "    barInnerRadius: " + barInnerRadius + ",\n" +
            "    quickMenuBorderWidth: " + quickMenuBorderWidth + ",\n" +
            "    quickMenuCornerRadius: " + quickMenuCornerRadius + ",\n" +
            "    quickMenuInnerRadius: " + quickMenuInnerRadius + ",\n" +
            '    osdPosition: "' + jsStr(osdPosition) + '",\n' +
            "    osdCornerRadius: " + osdCornerRadius + ",\n" +
            "    osdMargin: " + osdMargin + ",\n" +
            "    foxStatusBar: " + foxStatusBar + ",\n" +
            "}\n"
        var tmpFile = qsBarDir + "/settings.js.tmp"
        var escaped = js.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\$/g, "\\$").replace(/`/g, "\\`")
        settingsWriteProc.command = ["bash", "-c",
            "printf \"%s\" \"" + escaped + "\" > \"" + tmpFile + "\" && mv \"" + tmpFile + "\" \"" + qsBarDir + "/settings.js\""]
        settingsWriteProc.running = true
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
        watchChanges: false
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
        if (!colorHex || typeof colorHex !== "string" || colorHex.length < 7) return 0.5
        var r = parseInt(colorHex.substring(1, 3), 16) / 255
        var g = parseInt(colorHex.substring(3, 5), 16) / 255
        var b = parseInt(colorHex.substring(5, 7), 16) / 255
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    // blend two hex colors
    function mixHex(baseHex, accentHex, amount) {
        if (!baseHex || typeof baseHex !== "string" || baseHex.length < 7) return accentHex || "#808080"
        if (!accentHex || typeof accentHex !== "string" || accentHex.length < 7) return baseHex || "#808080"
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
    property bool clockShowDate: false
    property int batteryLevel: -1
    property string batteryStatus: "Unknown"
    property int brightnessLevel: -1
    property bool isQuickMenuOpen: false
    property bool foxStatusBar: false
    property bool isPowerPageOpen: false
    property bool isNotificationPageOpen: false
    property bool isWallpaperPageOpen: false
    property bool isClipboardPageOpen: false
    property bool isSettingsPageOpen: false
    property bool isSettingsWindowOpen: false
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

    readonly property real barSideMargin: root.safeScreen ? root.safeScreen.width * 0.2 : 800 * 0.2

    property real barFaceHeight: 46 * root.uiScale

    readonly property var safeScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    readonly property real uiScale: {
        if (!root.safeScreen) return 1.0
        var dpi = (root.safeScreen.logicalPixelDensity * 25.4) / 96
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
        root.nightLightDirty = true
        nightLightApplyProc.command = ["bash", swayScriptsDir + "/nightlight-apply",
            root.nightLight ? "on" : "off", root.nightLightIntensity + ""]
        nightLightApplyProc.running = true
        nightLightDirtyClear.restart()
    }

    function toggleCaffeine() {
        root.isCaffeineEnabled = !root.isCaffeineEnabled
        root.caffeineDirty = true
        if (root.isCaffeineEnabled) {
            // Stop swayidle (kills both lock timeout and DPMS off)
            caffeineProc.command = ["bash", "-c",
                "pkill -f 'swayidle' 2>/dev/null || true\n" +
                "systemd-inhibit --what=idle --who=quickshell --why=Caffeine &\necho $! > ~/.cache/quickshell-caffeine.pid"]
        } else {
            // Kill the inhibit, restart swayidle with original config
            caffeineProc.command = ["bash", "-c",
                "test -f ~/.cache/quickshell-caffeine.pid && kill $(cat ~/.cache/quickshell-caffeine.pid) 2>/dev/null; rm -f ~/.cache/quickshell-caffeine.pid\n" +
                "swayidle -w \\\n" +
                "    timeout 300 '$HOME/.config/sway/scripts/lock.sh' \\\n" +
                "    timeout 600 'swaymsg \"output * dpms off\"' \\\n" +
                "           resume 'swaymsg \"output * dpms on\"' \\\n" +
                "    before-sleep '$HOME/.config/sway/scripts/lock.sh' &"]
        }
        caffeineProc.startDetached()
        root.saveRiceSettings()
    }

    Timer {
        id: nightLightDirtyClear
        interval: 1000
        onTriggered: root.nightLightDirty = false
    }

    Timer {
        id: nightLightIntensityDirtyClear
        interval: 1000
        onTriggered: root.nightLightIntensityDirty = false
    }

    function setNightLightIntensity(v): void {
        root.nightLightIntensity = v
        root.nightLightIntensityDirty = true
        // auto-enable night light when intensity > 0
        if (v > 0 && !root.nightLight) {
            root.nightLight = true
        } else if (v === 0 && root.nightLight) {
            root.nightLight = false
        }
        nightLightApplyProc.command = ["bash", swayScriptsDir + "/nightlight-apply",
            root.nightLight ? "on" : "off", v + ""]
        nightLightApplyProc.running = true
        nightLightIntensityDirtyClear.restart()
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
        var monthsFull = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        root.dateText = d.getDate() + "-" + months[d.getMonth()] + "-" + String(d.getFullYear()).slice(-2)
        var h = d.getHours(), m = d.getMinutes()
        root.timeText = (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
        root.dateTimeText = d.getDate() + " " + monthsFull[d.getMonth()] + ", " + root.timeText
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
        interval: 15
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
        id: caffeineProc
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

    Component { id: foxBarComp; BarWindow {} }
    Component { id: catBarComp; CatBar {} }

    Loader {
        id: barLoader
        sourceComponent: root.activeBar === "cat" ? catBarComp
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
        horizontalMargin: {
            var raw = root.clockCenterFromBarLeft * root.uiScale - clockTip.implicitWidth / 2;
            var margin = root.barFullWidth ? raw : root.barSideMargin + raw;
            var maxLeft = root.safeScreen ? root.safeScreen.width - clockTip.implicitWidth : 1920;
            return Math.max(0, Math.min(margin, maxLeft));
        }
        horizontalPadding: 28 * root.uiScale
        verticalPadding: 14 * root.uiScale

        Row {
            spacing: 10 * root.uiScale

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

    SettingsWindow {}

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
        function openSettings(): void { root.openQuickMenuPage("Settings") }
        function openSettingsWindow(): void { root.isSettingsWindowOpen = !root.isSettingsWindowOpen }

        function setBar(mode): void {
            if (["fox", "cat"].indexOf(mode) === -1) return
            root.activeBar = mode
            root.saveRiceSettings()
        }

        // reload palette from colors.js
        function applyColors(): void {
            root.applyColors()
        }

        // reload settings from disk
        function reloadSettings(): void {
            root.parseRiceSettings()
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
            nightLightStartupProc.command = [swayScriptsDir + "/nightlight-toggle", "on", root.nightLightIntensity + ""]
            nightLightStartupProc.startDetached()
        }
        if (root.isCaffeineEnabled) {
            caffeineProc.command = ["bash", "-c",
                "pkill -f 'swayidle' 2>/dev/null || true\n" +
                "systemd-inhibit --what=idle --who=quickshell --why=Caffeine &\necho $! > ~/.cache/quickshell-caffeine.pid"]
            caffeineProc.startDetached()
        }
    }
}
