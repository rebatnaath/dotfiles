#!/usr/bin/env bash
# Tint the fastfetch lain logo with the current wallpaper palette.
# Reads the matugen primary color for the active mode and colorizes a
# grayscale copy of the source image; output goes to the fastfetch cache.
# Skips work when the palette and source are unchanged.
set -euo pipefail

SRC="$HOME/.config/fastfetch/image/lain.png"
OUT="$HOME/.cache/fastfetch-lain-tinted.png"
MODE_FILE="$HOME/.cache/sway-theme.json"
MATUGEN="$HOME/.cache/matugen.json"

[[ -f "$SRC" && -f "$MATUGEN" ]] || exit 0

mode="dark"
[[ -f "$MODE_FILE" ]] && mode="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("mode","dark"))' "$MODE_FILE" 2>/dev/null || echo dark)"

accent="$(python3 -c '
import json,sys
d=json.load(open(sys.argv[1]))
c=d["colors"]["primary"][sys.argv[2]]
print(c["color"] if isinstance(c,dict) else c)
' "$MATUGEN" "$mode" 2>/dev/null || echo "#ffb691")"

# regenerate only when source or accent changed
if [[ -f "$OUT" ]] && [[ "$OUT" -nt "$SRC" ]] && \
   [[ "$(cat "$OUT.tint" 2>/dev/null || echo)" == "$accent" ]]; then
    exit 0
fi

magick "$SRC" -colorspace gray \
    \( -clone 0 -fill "$accent" -colorize 100 \) \
    -compose blend -define compose:args=35,65 -composite \
    "$OUT"
printf '%s' "$accent" > "$OUT.tint"
