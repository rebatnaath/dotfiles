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
| `nvim/`     | neovim config                                           |
| `fastfetch/` | fastfetch system info config                                       |

## Install

Clone and symlink the dirs you want into `~/.config/`:

```sh
git clone https://github.com/rebatnaath/dotfiles ~/dotfiles
ln -sf ~/dotfiles/sway ~/.config/sway
ln -sf ~/dotfiles/quickshell ~/.config/quickshell
ln -sf ~/dotfiles/kitty ~/.config/kitty
ln -sf ~/dotfiles/rofi ~/.config/rofi
ln -sf ~/dotfiles/nvim ~/.config/nvim
ln -sf ~/dotfiles/fastfetch ~/.config/fastfetch
```

## Wallpapers

The wallpaper directory is **not part of this repo** — it lives in
[nixConfig](https://github.com/rebatnaath/nixConfig)`/assets/walls`. After
cloning/symlinking, point the scripts at your own wallpaper folder by editing
the `WALLS` path in these two files:

- `sway/scripts/wall-pick` — change the `WALLS="${WALLS_DIR:-...}"` line to your
  wallpaper directory (or export a `WALLS_DIR` env var instead).
- `sway/scripts/theme-switch` — update the `NERV_WALL` / `sand-dune` default
  paths (lines ~44–45 and ~88) to your own images.

## Requirements

`.config`-managed rice for my NixOS desktop, with the full setup in
https://github.com/rebatnaath/nixConfig. This repo holds just the configs
themselves; the flake there installs the required packages.

Minimum to run this config on a distro of your own:

- **SwayFX** (or sway) with XWayland
- **Quickshell** (bar, OSD, notifications, picker)
- **kitty** terminal
- **rofi** app launcher
- **matugen** (wallpaper → color-scheme generation)
- **swaybg** / **swaylock** / **swayidle**
- **grim** + **slurp** (screenshots), **wl-clipboard** (clipboard)
- **cliphist** (clipboard history), **wl-screenrec** (recording)
- **brightnessctl**, **wireplumber**, **libnotify**
- **ImageMagick** (wallpaper thumbnails)

See [nixConfig](https://github.com/rebatnaath/nixConfig) for the full list.