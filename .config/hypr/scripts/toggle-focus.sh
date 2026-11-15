#!/usr/bin/env bash
set -u

# Mod+A toggle: switches between eye-candy and no-distraction (focus) mode.
# Focus mode: gaps 3/8, no blur, no rounding, no shadows, no animations,
# opaque rofi, opaque dunst, opaque kitty. Second press restores
# everything.
#
# The eye-candy values below mirror hyprland.lua (gaps 6/15, rounding 14).

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/focus-mode"
ROFI_DIR="$HOME/.config/hypr/rofi"
DUNSTRC="$HOME/.config/dunst/dunstrc"
KITTY_CONF="$HOME/.config/kitty/kitty.conf"

mkdir -p "$(dirname "$STATE")"

# Serialize concurrent invocations (rapid double-press / testing races)
LOCK="${XDG_RUNTIME_DIR:-/tmp}/focus-mode.lock"
exec 9>"$LOCK"
if ! flock -w 10 9; then
    echo "toggle-focus: could not acquire lock" >&2
    exit 1
fi

mode="eye"
[[ -f "$STATE" ]] && mode=$(cat "$STATE")

if [[ "$mode" == "focus" ]]; then
    # ---- Restore eye-candy mode ----
    hyprctl eval "hl.config({general={gaps_in=6, gaps_out=15}, decoration={rounding=14, blur={enabled=true}, shadow={enabled=true}}, animations={enabled=true}})" >/dev/null

    sed -E -i 's/(transparency:[[:space:]]*)"no";/\1"real";/' "$ROFI_DIR"/*.rasi
    sed -i 's/border-radius: 0px;/border-radius: 32px;/g' "$ROFI_DIR"/*.rasi

    if grep -qE '^[[:space:]]*transparency = 0$' "$DUNSTRC"; then
        sed -E -i 's/^([[:space:]]*)transparency = 0$/\1transparency = 5/' "$DUNSTRC"
        sed -E -i 's/^([[:space:]]*)corner_radius = 0$/\1corner_radius = 2/' "$DUNSTRC"
        dunstctl reload >/dev/null 2>&1 || true
    fi

    opacity=$(awk '/^background_opacity/ {print $2; exit}' "$KITTY_CONF")
    kitten @ set-background-opacity --all "${opacity:-0.95}" >/dev/null 2>&1 || true

    echo "eye" > "$STATE"
    notify-send "Eye-candy mode" "Transparency, blur, rounding and animations restored"

else
    # ---- Enter focus mode ----
    hyprctl eval "hl.config({general={gaps_in=3, gaps_out=8}, decoration={rounding=0, blur={enabled=false}, shadow={enabled=false}}, animations={enabled=false}})" >/dev/null

    sed -E -i 's/(transparency:[[:space:]]*)"real";/\1"no";/' "$ROFI_DIR"/*.rasi
    sed -i 's/border-radius: 32px;/border-radius: 0px;/g' "$ROFI_DIR"/*.rasi

    if grep -qE '^[[:space:]]*transparency = 5$' "$DUNSTRC"; then
        sed -E -i 's/^([[:space:]]*)transparency = 5$/\1transparency = 0/' "$DUNSTRC"
        sed -E -i 's/^([[:space:]]*)corner_radius = 2$/\1corner_radius = 0/' "$DUNSTRC"
        dunstctl reload >/dev/null 2>&1 || true
    fi

    kitten @ set-background-opacity --all 1.0 >/dev/null 2>&1 || true

    echo "focus" > "$STATE"
    notify-send "Focus mode" "No-distraction mode: gaps 3/8, no blur, rounding, animations or transparency"
fi
