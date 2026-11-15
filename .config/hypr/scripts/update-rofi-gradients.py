import colorsys
import json
import os
from pathlib import Path

home = Path.home()
cache_home = Path(os.environ.get("XDG_CACHE_HOME", home / ".cache"))
accents = json.loads(
    (cache_home / "desktop-theme/accents.json").read_text()
)["accents"]


def rgb(value):
    value = (value or "").strip().lstrip("#")
    if len(value) != 6:
        raise ValueError(f"not a hex colour: {value!r}")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def accent(name):
    # A missing or malformed accent must not abort the wallpaper script:
    # aborting here used to skip the Waybar, border and Kitty reloads.
    try:
        return rgb(accents[name]["color"])
    except (KeyError, TypeError, ValueError) as error:
        print(f"Warning: ignoring bad accent {name}: {error}")
        return (140, 140, 146)


def to_hex(values):
    return "#" + "".join(
        f"{max(0, min(255, round(v))):02X}" for v in values
    )


# Turn an accent into a light tint that still reads as the wallpaper's
# colour. The old version desaturated and blended 45% towards near-white,
# which turned every theme into silver. Hue is kept, saturation is capped
# for a soft pastel look, and lightness is floored so the dark text drawn
# on top of these gradients stays readable.
def soften(color):
    r, g, b = (channel / 255 for channel in color)
    hue, lightness, sat = colorsys.rgb_to_hls(r, g, b)

    lightness = max(lightness, 0.62)
    sat = min(sat, 0.45)

    r, g, b = colorsys.hls_to_rgb(hue, lightness, sat)
    return (r * 255, g * 255, b * 255)


# Use only the two dominant extracted wallpaper accents.
anchors = [
    soften(accent("primary")),
    soften(accent("secondary"))
]


# Generate seven evenly spaced gradient stops.
def make_gradient(palette):
    stops = []

    for i in range(7):
        pos = i / 6 * (len(palette) - 1)
        idx = min(int(pos), len(palette) - 2)
        t = pos - idx

        color = tuple(
            palette[idx][c] * (1 - t) +
            palette[idx + 1][c] * t
            for c in range(3)
        )

        stops.append(to_hex(color))

    return "linear-gradient(to right, " + ", ".join(stops) + ")"


gradient = make_gradient(anchors)


# Update Rofi themes.
root = home / ".config/hypr/rofi"

for name in sorted(f.name for f in root.glob("*.rasi")):
    path = root / name
    original = path.read_text()

    output = []
    in_target = False

    for line in original.splitlines():
        stripped = line.strip()

        if stripped in (
            # Prompt pills are text labels: the themes give them a deep
            # background + neon text (same pattern as the Waybar widget
            # pills), so gradients are no longer force-injected here.
            "element selected.normal {",
            "button selected {",
        ):
            output.append(line)
            output.append("    background-image: " + gradient + ";")
            in_target = True
            continue

        if in_target and stripped == "}":
            in_target = False

        # One gradient per block: drop the copy that was already there so
        # repeated runs stop appending duplicate lines.
        if in_target and "background-image: linear-gradient(" in line:
            continue

        if in_target and stripped.startswith("background-color:") and any(
            value in stripped
            for value in ("var(selected)", "var(active)", "var(urgent)")
        ):
            continue

        if "background-image: linear-gradient(" in line:
            indent = line[:len(line) - len(line.lstrip())]
            line = indent + "background-image: " + gradient + ";"

        output.append(line)

    path.write_text("\n".join(output) + "\n")
    print(f"Updated Rofi: {name}")


# Keep the launcher search-icon background transparent.
launcher = root / "launcher.rasi"

if launcher.exists():
    lines = launcher.read_text().splitlines()
    output = []
    in_icon = False

    for line in lines:
        stripped = line.strip()

        if stripped == "textbox-prompt-colon {":
            in_icon = True
            output.append(line)
            continue

        if in_icon and stripped == "}":
            output.append("    background-color: transparent;")
            output.append(line)
            in_icon = False
            continue

        if in_icon and (
            stripped.startswith("background-image:") or
            stripped.startswith("background-color:")
        ):
            continue

        output.append(line)

    launcher.write_text("\n".join(output) + "\n")


# Apply the same pastel gradient to every Waybar mode.
for mode in ("waybar", "waybar-island", "waybar-circular"):
    waybar = home / ".config" / mode / "style.css"

    if not waybar.exists():
        continue

    lines = waybar.read_text().splitlines()
    output = []
    replaced = 0

    for line in lines:
        if "background-image: linear-gradient(" in line or (mode == "waybar-island" and line.strip() == "background: @blue;" and any("#pulseaudio-slider highlight {" in x for x in output[-4:])):
            indent = line[:len(line) - len(line.lstrip())]
            line = indent + "background-image: " + gradient + ";"
            replaced += 1

        output.append(line)

    waybar.write_text("\n".join(output) + "\n")
    print(f"Updated {mode}: {replaced} gradients.")

print("Wallpaper gradients updated.")
