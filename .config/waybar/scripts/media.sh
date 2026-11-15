#!/usr/bin/env bash
action="${1:-title}"

# Combined waybar label: icon alone when idle, "icon title" otherwise.
if [ "$action" = "widget" ]; then
    icon=$("$0" toggle-icon)
    title=$("$0" title)
    if [ -z "$title" ] || [ "$title" = "No media" ]; then
        printf '%s  %s\n' "$icon" "No media playing"
    else
        printf '%s  %s\n' "$icon" "$title"
    fi
    exit 0
fi

player=""
paused_fallback=""
metadata_fallback=""

while IFS= read -r p; do
    [ -n "$p" ] || continue
    status=$(playerctl -p "$p" status 2>/dev/null || true)
    if [ "$status" = Playing ]; then
        player="$p"
        break
    fi
    title=$(playerctl -p "$p" metadata --format "{{artist}} - {{title}}" 2>/dev/null || true)
    if [ -n "$title" ] && [ "$title" != " - " ]; then
        [ -z "$metadata_fallback" ] && metadata_fallback="$p"
        [ "$status" = Paused ] && paused_fallback="$p"
    fi
done < <(playerctl -l 2>/dev/null || true)

if [ -z "$player" ]; then
    player="${paused_fallback:-$metadata_fallback}"
fi

if [ -z "$player" ]; then
    case "$action" in
        title) echo "No media" ;;
        toggle-icon) echo "" ;;
    esac
    exit 0
fi

case "$action" in
    prev) if [[ "$player" == brave.* ]]; then ~/.config/waybar/scripts/brave-media-control.py prev; else playerctl -p "$player" previous; fi ;;
    next) if [[ "$player" == brave.* ]]; then ~/.config/waybar/scripts/brave-media-control.py next; else playerctl -p "$player" next; fi ;;
    toggle) playerctl -p "$player" play-pause; sleep 0.15; pkill -RTMIN+8 -x waybar 2>/dev/null || true ;;
    toggle-icon) if [ "$(playerctl -p "$player" status 2>/dev/null)" = Playing ]; then echo ""; else echo ""; fi ;;
    title) playerctl -p "$player" metadata --format "{{artist}} - {{title}}" 2>/dev/null | cut -c1-25 ;;
esac
