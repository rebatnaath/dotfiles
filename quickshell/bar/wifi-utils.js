.pragma library

// Shared WiFi utilities for parsing nmcli output.
// Used by QuickMenu, WifiPage, and WifiInline.

function parseNmcliList(text) {
    var entries = []
    var lines = text.split("\n")
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim()
        if (line === "" || line.indexOf("IN-USE") === 0) continue
        var parts = line.split(":")
        if (parts.length < 4) continue
        entries.push({
            connected: parts[0].trim() === "*",
            ssid: parts[1].trim(),
            signal: parseInt(parts[2].trim()) || 0,
            security: parts[3].trim()
        })
    }
    return entries
}

function populateModel(model, text) {
    model.clear()
    var entries = parseNmcliList(text)
    for (var k = 0; k < entries.length; k++) {
        model.append(entries[k])
    }
}
