import sys
import json
import re
import os

def parse_histogram(hist_file):
    """Parse ImageMagick histogram and return list of (luminance, saturation, hex) tuples."""
    data = []
    with open(hist_file) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            # Format like: #FFB4AB or (#FFB4AB, 7)
            hex = line.strip()
            hex = hex.lstrip('(#)')
            if len(hex) == 6:
                r = int(hex[0:2], 16)
                g = int(hex[2:4], 16)
                b = int(hex[4:6], 16)
                # luminance (perceived brightness)
                l = 0.299 * r + 0.587 * g + 0.114 * b
                l = l / 255.0  # normalize to 0-1
                # saturation
                mx = max(r, g, b)
                mn = min(r, g, b)
                s = 0 if mx == 0 else (mx - mn) / max(1, 255 - mn)
                data.append((l, s, hex.upper()))
    # Sort by luminance (desc), then saturation (desc)
    data.sort(key=lambda x: (x[0], x[1]), reverse=True)
    return data

def parse_histogram_lines(lines):
    """Pull hex colours out of `magick ... histogram:info:-` output.

    Handles both `#RRGGBB` and `#RRGGBBAA` (transparency-aware images).
    Fully transparent pixels are ignored because their colour is invisible.
    """
    colors = []
    for line in lines:
        for token in line.split():
            if not token.startswith("#"):
                continue
            hexv = token.lstrip("#").strip("()")
            if len(hexv) == 9:
                if int(hexv[6:8], 16) < 0x80:
                    break
                hexv = hexv[:6]
            if len(hexv) != 6:
                break
            try:
                int(hexv, 16)
            except ValueError:
                break
            colors.append(hexv.upper())
            break
    return colors


def luminance(hexv):
    r, g, b = (int(hexv[i:i + 2], 16) for i in (0, 2, 4))
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255.0


def distance(a, b):
    return sum(
        (int(a[i:i + 2], 16) - int(b[i:i + 2], 16)) ** 2 for i in (0, 2, 4)
    ) ** 0.5


def saturation(hexv):
    r, g, b = (int(hexv[i:i + 2], 16) for i in (0, 2, 4))
    high, low = max(r, g, b), min(r, g, b)
    return 0 if high == 0 else (high - low) / high


def select_colors(colors):
    """Pick three visible, well-separated colours.

    The most frequent visible colour anchors the palette (the dominant
    background). The second colour is the most *saturated* colour clearly
    different from the anchor: pure distance picks extreme outliers, so a
    blue night scene ended up themed by one small cream doorway. The third
    colour maximises distance again for contrast.
    """
    uniq = list(dict.fromkeys(colors))
    if not uniq:
        return []

    visible = [c for c in uniq if 0.10 <= luminance(c) <= 0.97]
    pool = visible or uniq

    chosen = [pool[0]]

    rest = [c for c in pool if c not in chosen]
    if rest:
        separated = [c for c in rest if distance(c, chosen[0]) >= 90]
        if separated:
            # pool is frequency-ordered, so ties keep the commoner colour.
            chosen.append(max(separated, key=saturation))
        else:
            chosen.append(
                max(rest, key=lambda c: min(distance(c, p) for p in chosen))
            )

    while len(chosen) < 3:
        rest = [c for c in pool if c not in chosen]
        if not rest:
            break
        chosen.append(
            max(rest, key=lambda c: min(distance(c, picked) for picked in chosen))
        )

    while len(chosen) < 3:
        chosen.append(chosen[-1])
    return chosen[:3]


def write_accents(primary, secondary, muted):
    """Write accents.json with the given colors."""
    data = {
        "accents": {
            "primary": {"color": primary},
            "secondary": {"color": secondary},
            "tertiary": {"color": muted},
            "primaryContainer": {"color": primary},
            "secondaryContainer": {"color": secondary},
            "tertiaryContainer": {"color": muted},
            "primaryFixed": {"color": primary},
            "secondaryFixed": {"color": secondary},
            "tertiaryFixed": {"color": muted},
            "primaryFixedDim": {"color": primary},
            "secondaryFixedDim": {"color": secondary},
            "tertiaryFixedDim": {"color": muted},
            "muted": {"color": muted}
        }
    }
    cache_home = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    output_path = cache_home / "desktop-theme/accents.json"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w') as f:
        json.dump(data, f, indent=2)

if __name__ == "__main__":
    if len(sys.argv) >= 2 and sys.argv[1] == "parse":
        hist_file = sys.argv[2] if len(sys.argv) >= 3 else "/tmp/test.txt"
        data = parse_histogram(hist_file)
        for l, s, h in data[:32]:
            print(f"{l:.4f} {s:.4f} {h}")
    elif len(sys.argv) >= 2 and sys.argv[1] == "select":
        # Reads `histogram:info:-` output on stdin, prints three hex colours.
        for color in select_colors(parse_histogram_lines(sys.stdin)):
            print(color)
    elif len(sys.argv) >= 5 and sys.argv[1] == "write":
        write_accents(sys.argv[2], sys.argv[3], sys.argv[4])
    else:
        print("Usage: extract_helper.py parse <hist_file> | extract_helper.py write <primary> <secondary> <muted>", file=sys.stderr)
