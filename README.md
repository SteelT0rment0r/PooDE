# PooDE

A portable Hyprland desktop configuration.

## Requirements

- Hyprland 0.55+
- ScrollOverview plugin (compatible with your Hyprland version)
- Waybar
- Rofi
- Kitty
- Yazi
- Dunst
- Matugen
- awww
- Fish
- Bash
- Python 3
- jq
- ImageMagick
- D-Bus
- inotify-tools
- util-linux (`flock`)
- procps (`pgrep`, `pkill`)
- coreutils, findutils, grep, sed, gawk
- libnotify
- wl-clipboard
- grim
- slurp
- wf-recorder
- xdg-user-dirs
- cliphist
- playerctl
- brightnessctl
- PipeWire + WirePlumber
- PipeWire PulseAudio compatibility (`paplay`)
- elogind or systemd-logind

## Optional integrations

- Viewnior — screenshot previews
- NetworkManager — network management (`nmtui`)
- BlueZ — Bluetooth management (`bluetoothctl`)
- power-profiles-daemon — power profiles
- MPD + rmpc — music player
- Zen Browser — browser shortcut
- GTK3/GTK4 themes — GTK theming

## Installation

Back up your existing configuration first.

Clone the repository:

```sh
git clone https://github.com/SteelT0rment0r/PooDE
cd PooDE
```

Copy the configuration:

```sh
mkdir -p ~/.config
cp -a .config/. ~/.config/
```

Copy wallpapers:

```sh
mkdir -p ~/Pictures/Wallpapers
cp -a wallpapers/. ~/Pictures/Wallpapers/
```

Install ScrollOverview using its installation instructions, then reload its plugins:

```sh
hyprpm reload
```

Log out and start Hyprland.

## Notes

- Configuration is managed manually.
- Existing configuration files may be overwritten.
- Wallpaper selection and theming use Matugen.
- Three Waybar styles are included.
- Four Hyprland layouts are included: scrolling, dwindle, master and monocle.
- No distro-specific package manager is required.

