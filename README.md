# dotfiles

This was a personal SwayFX rice for myself — since a few of you asked for the
dotfiles, I'm posting them here. I'd like to be helpful, and some of you might
be new to this kind of thing (or not), so that's why the README is a bit
detailed. Don't cringe on me, please.

> **Important:** a few of these configurations might work, might not — there
> could be bugs and what-not. It works on *my* system, but I don't know about
> yours. It was only tested on a single-monitor 1920x1080 display; no idea about
> anything else. If you just want to steal the bar or the quickmenu config,
> that's totally fine. But if you're going to literally use this whole thing as
> your system, I won't be liable if it breaks anything. If you really want
> something fixed and don't know how, open an issue — depending on how
> free/busy I am, I might patch it and let you know.

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

<table>
  <tr>
    <td align="center"><b>Fox</b><br><img src="assets/fox-1.png" width="320"><br><img src="assets/fox-2.png" width="320"></td>
    <td align="center"><b>Lonely</b><br><img src="assets/lonely-1.png" width="320"><br><img src="assets/lonely-2.png" width="320"></td>
    <td align="center"><b>Nerv</b><br><img src="assets/nerv-1.png" width="320"><br><img src="assets/nerv-2.png" width="320"></td>
  </tr>
</table>

## Control menu

There is one shared control menu (the Quickshell quick menu) used by every bar
variant. All bars open it by clicking a spot in their own layout:

- **Fox** — click the `ctrls` button on the right.
- **Lonely** — click any of the right info blocks (`[bat]`, `[vol]`, `[time]`).
- **Nerv** — click the `MAGI SYSTEM` label on the right.

The menu's colours follow the bar. For **nerv** the whole control center is the
fixed EVA red and cannot be rethemed at runtime; for **fox** and **lonely** it
picks up the wallpaper-derived matugen palette, so it follows whatever
wallpaper you apply.

The menu is the **control center** (bluetooth, wifi, brightness, volume, media)
plus a set of pages, each with its own panel (the control center recolours live
when you change the wallpaper for fox/lonely; the nerv control center is always
the fixed EVA red):

<table>
  <tr>
    <td align="center"><img src="assets/ctrl-overview.png" width="180"><br><b>Control center</b></td>
    <td align="center"><img src="assets/ctrl-wallpaper.png" width="180"><br><b>Wallpaper picker</b></td>
    <td align="center"><img src="assets/ctrl-tweaks.png" width="180"><br><b>Tweaks / Super+W</b></td>
    <td align="center"><img src="assets/ctrl-clipboard.png" width="180"><br><b>Clipboard</b></td>
  </tr>
  <tr>
    <td align="center"><img src="assets/ctrl-notification.png" width="180"><br><b>Notifications</b></td>
    <td align="center"><img src="assets/ctrl-power.png" width="180"><br><b>Power menu</b></td>
    <td align="center"><img src="assets/example-control-center-color-change-wallpaper.png" width="180"><br><b>Recolours with wallpaper</b></td>
    <td align="center"><img src="assets/nerv-contrl-center.png" width="180"><br><b>Nerv control center (fixed red)</b></td>
  </tr>
</table>

The bar also drives its own on-screen displays:

<table>
  <tr>
    <td align="center"><img src="assets/volume-osd.png"><br><b>Volume OSD</b></td>
    <td align="center"><img src="assets/notification-osd.png"><br><b>Notification OSD</b></td>
  </tr>
</table>

You can tweak which pages appear and how things behave; the pages and hotkeys
live in `quickshell/bar/QuickMenu.qml`.

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