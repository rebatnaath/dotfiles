# dotfiles

Personal desktop configuration: **Sway** (SwayFX) + **Quickshell** bar, plus
the supporting terminal/theme tooling. The companion `nixConfig` repo contains
the NixOS setup that installs the packages; this repo holds the raw configs
that you can drop straight into `~/.config/`.

## Contents

| Dir          | What it is                                                        |
|--------------|-------------------------------------------------------------------|
| `sway/`      | SwayFX config, keybinds, autostart, and helper scripts            |
| `quickshell/`| Quickshell bar, OSD, notifications, lockscreen, powermenu, picker |
| `kitty/`     | kitty terminal config                                              |
| `rofi/`      | rofi launcher themes/config                                        |
| `nvim/`      | neovim config (transparent, minimal)                               |
| `fastfetch/` | fastfetch system info config                                       |

## Install

Clone and symlink the dirs you want into `~/.config/`:

```sh
git clone https://github.com/USERNAME/dotfiles ~/dotfiles
ln -sf ~/dotfiles/sway ~/.config/sway
ln -sf ~/dotfiles/quickshell ~/.config/quickshell
ln -sf ~/dotfiles/kitty ~/.config/kitty
ln -sf ~/dotfiles/rofi ~/.config/rofi
ln -sf ~/dotfiles/nvim ~/.config/nvim
ln -sf ~/dotfiles/fastfetch ~/.config/fastfetch
```

(The `.cache` files the scripts generate — quickshell picker data — are
gitignored and recreated on demand.)

## Requirements

- **SwayFX** (or sway) with the packages from `nixConfig`: `swaybg`, `matugen`,
  `grim`, `slurp`, `cliphist`, `quickshell`, `kitty`, `rofi`, etc.
- `quickshell` bar needs the Quickshell package.

See `../nixConfig` (or the `nixConfig` repo) for the full package list.