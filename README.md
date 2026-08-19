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

## Requirements

`.config`-managed rice for my NixOS desktop, with the full setup in
https://github.com/rebatnaath/nixConfig. This repo holds just the configs
themselves; the flake there installs the required packages.