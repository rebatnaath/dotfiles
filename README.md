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

## Bars & themes

The Quickshell bar ships with two bar types plus a separate accent theme
(switch with `activeBar` in `quickshell/bar/settings.js`):

- **Fox** — a foxes themed bottom bar.
- **Lonely** — a single-colour accent bar (focused workspace + window title
  share the lightest matugen tone, inactive workspaces get darkened chips).

**Nerv** — a separate Evangelion theme: the EVA backdrop plus 20 character
icons rendered on the bar, lock, and power menu.

**Fox**
![fox-bar-1](assets/fox-1.png) · ![fox-bar-2](assets/fox-2.png)

**Lonely**
![lonely-bar-1](assets/lonely-1.png) · ![lonely-bar-2](assets/lonely-2.png)

**Nerv**
![nerv-bar-1](assets/nerv-1.png) · ![nerv-bar-2](assets/nerv-2.png)

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

- `sway/scripts/wall-pick` — change the `WALLS` line to your wallpaper
  directory (or export a `WALLS_DIR` env var instead):

  ```sh
  WALLS="${WALLS_DIR:-$HOME/nixConfig/assets/walls}"
  ```

- `sway/scripts/theme-switch` — update the `NERV_WALL` fallback defaults and
  the restore-image path to your own images:

  ```sh
  NERV_WALL="$HOME/nixConfig/assets/walls/eva/main.png"
  [[ -f "$NERV_WALL" ]] || NERV_WALL="$HOME/nixConfig/assets/walls/sand-dune.jpg"
  update_wall_link "$HOME/nixConfig/assets/walls/sand-dune.jpg"
  ```

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