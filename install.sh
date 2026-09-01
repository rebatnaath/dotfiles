#!/bin/bash
# Dotfiles install script
# Backs up existing configs and symlinks the new ones

set -e

DOTFILES="$HOME/dotfiles"
BACKUP_DIR="$HOME/.config-backup/$(date +%Y%m%d-%H%M%S)"

# Configs to install
CONFIGS=(
    sway
    quickshell
    kitty
    rofi
    nvim
    fastfetch
)

echo "=== Dotfiles Installer ==="
echo ""
echo "This will symlink the following configs into ~/.config/:"
for config in "${CONFIGS[@]}"; do
    if [ -d "$HOME/.config/$config" ] && [ ! -L "$HOME/.config/$config" ]; then
        echo "  - $config (will backup existing)"
    elif [ -L "$HOME/.config/$config" ]; then
        echo "  - $config (already a symlink, will update)"
    else
        echo "  - $config (new)"
    fi
done
echo ""
read -p "Continue? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Create backup directory if needed
BACKUP_NEEDED=false
for config in "${CONFIGS[@]}"; do
    if [ -d "$HOME/.config/$config" ] && [ ! -L "$HOME/.config/$config" ]; then
        BACKUP_NEEDED=true
        break
    fi
done

if [ "$BACKUP_NEEDED" = true ]; then
    mkdir -p "$BACKUP_DIR"
    echo "Backing up existing configs to: $BACKUP_DIR"
    for config in "${CONFIGS[@]}"; do
        if [ -d "$HOME/.config/$config" ] && [ ! -L "$HOME/.config/$config" ]; then
            cp -r "$HOME/.config/$config" "$BACKUP_DIR/$config"
            echo "  Backed up: $config"
        fi
    done
fi

# Create symlinks
echo ""
echo "Creating symlinks..."
for config in "${CONFIGS[@]}"; do
    if [ -d "$DOTFILES/$config" ]; then
        rm -rf "$HOME/.config/$config"
        ln -sf "$DOTFILES/$config" "$HOME/.config/$config"
        echo "  Linked: $config"
    else
        echo "  Skipped: $config (not found in dotfiles)"
    fi
done

echo ""
echo "=== Done ==="
if [ "$BACKUP_NEEDED" = true ]; then
    echo "Old configs backed up to: $BACKUP_DIR"
fi
echo "You may need to restart your applications or log out/in for changes to take effect."
