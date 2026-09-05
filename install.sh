#!/bin/bash
set -e

DOTFILES="$HOME/dotfiles"
BACKUP="$HOME/.config-backup/$(date +%Y%m%d-%H%M%S)"
CONFIGS=(sway quickshell kitty rofi nvim fastfetch)

echo "WARNING: This will overwrite your existing configs for:"
echo "  ${CONFIGS[*]}"
echo ""

# Backup existing configs
mkdir -p "$BACKUP"
for c in "${CONFIGS[@]}"; do
    [ -d "$HOME/.config/$c" ] && [ ! -L "$HOME/.config/$c" ] && cp -r "$HOME/.config/$c" "$BACKUP/$c" && echo "Backed up: $c"
done

echo ""

# Copy new configs (overwrites existing)
for c in "${CONFIGS[@]}"; do
    if [ -d "$DOTFILES/$c" ]; then
        rm -rf "$HOME/.config/$c"
        cp -r "$DOTFILES/$c" "$HOME/.config/$c"
        echo "Installed: $c"
    fi
done

echo ""
echo "Done. Old configs saved to: $BACKUP"
