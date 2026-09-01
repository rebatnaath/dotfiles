#!/bin/bash
set -e

DOTFILES="$HOME/dotfiles"
BACKUP="$HOME/.config-backup/$(date +%Y%m%d-%H%M%S)"
CONFIGS=(sway quickshell kitty rofi nvim fastfetch)

echo "Backing up existing configs and symlinking new ones..."
echo ""

# Backup existing configs
mkdir -p "$BACKUP"
for c in "${CONFIGS[@]}"; do
    [ -d "$HOME/.config/$c" ] && [ ! -L "$HOME/.config/$c" ] && cp -r "$HOME/.config/$c" "$BACKUP/$c" && echo "Backed up: $c"
done

# Symlink new configs
for c in "${CONFIGS[@]}"; do
    [ -d "$DOTFILES/$c" ] && rm -rf "$HOME/.config/$c" && ln -sf "$DOTFILES/$c" "$HOME/.config/$c" && echo "Installed: $c"
done

echo ""
echo "Done. Old configs saved to: $BACKUP"
