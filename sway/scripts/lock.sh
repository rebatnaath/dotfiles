#!/usr/bin/env bash
# Lock the screen with the quickshell lockscreen. Pre-generates a blurred copy
# of the current wallpaper (~/.cache/lock-blur.png) for the backdrop (cached
# per wallpaper so only the first lock after a theme change is slow), then
# runs the lockscreen until unlocked, matching swaylock's behaviour so swayidle
# / super+L can lock again cleanly.
set -euo pipefail

# If caffeine mode is active, skip locking
if [[ -f "$HOME/.cache/caffeine-active" ]]; then
    exit 0
fi

STATE="$HOME/.cache/sway-theme.json"
LOCK_IMG="$HOME/.cache/lock-blur.png"
STAMP="$HOME/.cache/lock-blur.stamp"

WALL=""
if [[ -f "$STATE" ]]; then
    WALL="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("wallpaper",""))' "$STATE" 2>/dev/null || true)"
fi

# Only build the blurred image when a wallpaper exists and it changed.
if [[ -n "$WALL" && -f "$WALL" ]] && command -v magick >/dev/null 2>&1; then
    RES="$(swaymsg -t get_outputs --raw 2>/dev/null | python3 -c 'import json,sys; outs=json.load(sys.stdin); o=next((o for o in outs if o.get("focused")), outs[0]); print(str(o["rect"]["width"]) + "x" + str(o["rect"]["height"]))' 2>/dev/null || echo "1920x1080")"
    KEY="$(stat -c '%Y:%s' "$WALL")"
    if [[ ! -f "$LOCK_IMG" || "$(cat "$STAMP" 2>/dev/null || true)" != "$KEY" ]]; then
        HALF="${RES%x*}x$(( ${RES#*x} / 2 ))"
        magick "$WALL" -define "jpeg:size=${RES}" -resize "${RES}^" -gravity center -extent "$RES" \
            -resize "$HALF" -filter Gaussian -blur 0x6 -resize "${RES}^" -gravity center -extent "$RES" "$LOCK_IMG"
        echo "$KEY" > "$STAMP"
    fi
fi

# Prefer the installed quickshell binary, fall back to nix run until a rebuild
# (same pattern as the bar launcher). QS_LOCK=1 tells the config to actually
# lock (a bare launch is treated as a test and stays unlocked).
QS_BIN="$(command -v quickshell 2>/dev/null || true)"
export QS_LOCK=1
if [[ -n "$QS_BIN" ]]; then
    exec "$QS_BIN" -p "$HOME/.config/quickshell/lockscreen"
else
    exec nix run nixpkgs#quickshell -- -p "$HOME/.config/quickshell/lockscreen"
fi
