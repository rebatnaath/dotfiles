#!/usr/bin/env bash
# Launch the portal notification backend with a python that has dbus_next.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Prefer nix-shell, fall back to whatever python is present.
if command -v nix-shell >/dev/null 2>&1; then
    exec nix-shell -p python3.pkgs.dbus-next --run "python3 \"$SCRIPT_DIR/portal-notify-backend.py\""
elif command -v python3 >/dev/null 2>&1 && python3 -c "import dbus_next" 2>/dev/null; then
    exec python3 "$SCRIPT_DIR/portal-notify-backend.py"
else
    echo "portal-notify-backend: no python with dbus_next found" >&2
    exit 1
fi