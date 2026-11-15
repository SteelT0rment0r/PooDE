#!/usr/bin/env bash
set -u

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/waybar-mode"
mkdir -p "$(dirname "$STATE")"

# Usage: toggle-waybar.sh [cycle|start|restart]
#   cycle   (default) advance to the next mode
#   start   launch the saved mode without changing it (login)
#   restart relaunch the saved mode (wallpaper reload)
cmd="${1:-cycle}"

mode="floating"
if [[ -f "$STATE" ]]; then
    mode=$(cat "$STATE")
fi

case "$mode" in
    floating|island|circular) ;;
    *)
        mode="floating"
        ;;
esac

if [[ "$cmd" == "cycle" ]]; then
    case "$mode" in
        floating)  mode="island"    ;;
        island)    mode="circular" ;;
        circular)  mode="floating" ;;
    esac
fi

case "$mode" in
    island)    dir="$HOME/.config/waybar-island"    ;;
    circular)  dir="$HOME/.config/waybar-circular"  ;;
    *)         dir="$HOME/.config/waybar"           ;;
esac

config="$dir/config"
style="$dir/style.css"

log="/tmp/waybar-${mode}.log"

if [[ ! -f "$config" || ! -f "$style" ]]; then
    notify-send "Waybar toggle failed" "Missing config or stylesheet for $mode mode"
    exit 1
fi

# One restart at a time: concurrent pkill/launch pairs used to race and
# leave two bars on screen.
LOCK="${XDG_RUNTIME_DIR:-/tmp}/waybar-restart.lock"
exec 9>"$LOCK"
if ! flock -w 15 9; then
    echo "waybar restart: could not acquire lock" >&2
    exit 1
fi

pkill -x waybar 2>/dev/null || true
# Wait until the old bar is actually gone before starting a new one.
for _ in $(seq 1 30); do
    pgrep -x waybar >/dev/null || break
    sleep 0.1
done

# 9>&- : waybar must not inherit the lock descriptor, or it would hold
# the lock for its whole lifetime and block every future restart.
waybar -c "$config" -s "$style" >"$log" 2>&1 9>&- &

if [[ "$cmd" == "cycle" ]]; then
    echo "$mode" > "$STATE"
fi
