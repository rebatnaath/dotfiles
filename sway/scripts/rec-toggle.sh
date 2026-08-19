#!/usr/bin/env bash
# Toggle screen recording with wl-screenrec.
# First press starts recording the focused output, second press stops and saves.
set -euo pipefail

DIR="$HOME/Videos/Recordings"
PIDFILE="/tmp/wl-screenrec.pid"
LOG="$DIR/rec-errors.log"

if ! command -v wl-screenrec >/dev/null 2>&1; then
    notify-send -a "Screen Recorder" "wl-screenrec not installed" "Run 'nix rebuild' first" 2>/dev/null || true
    exit 1
fi

notify() { notify-send -a "Screen Recorder" "$1" "$2" 2>/dev/null || true; }

if [[ -f "$PIDFILE" ]] && kill -0 "$(sed -n 1p "$PIDFILE")" 2>/dev/null; then
    PID="$(sed -n 1p "$PIDFILE")"
    OUT="$(sed -n 2p "$PIDFILE")"
    kill -INT "$PID"
    # wait for wl-screenrec to finish encoding
    for _ in $(seq 1 50); do
        kill -0 "$PID" 2>/dev/null || break
        sleep 0.1
    done
    rm -f "$PIDFILE"
    notify "Recording stopped" "${OUT:-saved to $DIR}"
else
    rm -f "$PIDFILE"
    mkdir -p "$DIR"
    OUT="$DIR/rec-$(date +%Y-%m-%d_%H%M%S).mp4"

    # record the focused output; fall back to wl-screenrec's default (only display)
    OUTPUT="$(swaymsg -t get_outputs --raw 2>/dev/null | python3 -c 'import json,sys; outs=json.load(sys.stdin); print(next((o["name"] for o in outs if o.get("focused")), ""))' 2>/dev/null || true)"

    # --low-power=off: this GPU has no usable fixed-function H264 encoder, so
    # wl-screenrec fails on the low-power path and only works via the normal
    # VAAPI path. Ask for it directly so startup never silently dies leaving
    # an empty file behind. Stderr is kept in rec-errors.log for diagnostics.
    ARGS=()
    if [[ -n "$OUTPUT" ]]; then
        ARGS+=(-o "$OUTPUT")
    fi
    wl-screenrec --low-power=off "${ARGS[@]}" -f "$OUT" 2>>"$LOG" &
    PID=$!
    echo "$PID" > "$PIDFILE"
    echo "$OUT" >> "$PIDFILE"

    # Give it a moment to init the encoder; if it crashed, clean up and report.
    sleep 1
    if ! kill -0 "$PID" 2>/dev/null; then
        rm -f "$PIDFILE" "$OUT"
        notify "Recording failed" "see $LOG"
        exit 1
    fi
    notify "Recording started" "$OUT"
fi
