#!/usr/bin/env python3
import json
import colorsys
import sys

def luminosity(hex_color):
    """Calculate perceived luminance (0-1, 1=brightest)."""
    hex_color = hex_color.lstrip('#')
    rgb = tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
    return colorsys.rgb_to_hsv(rgb[0]/255, rgb[1]/255, rgb[2]/255)[2]

def brighten_if_dark(hex_color, threshold=0.3, factor=1.5):
    """Brighten color if luminance is below threshold."""
    hex_color = hex_color.lstrip('#')
    lum = luminosity(hex_color)
    if lum < threshold:
        rgb = tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
        h, s, v = colorsys.rgb_to_hsv(rgb[0]/255, rgb[1]/255, rgb[2]/255)
        new_v = min(1.0, v * factor)
        new_rgb = colorsys.hsv_to_rgb(h, s, new_v)
        new_color = '#%02X%02X%02X' % (int(new_rgb[0]*255), int(new_rgb[1]*255), int(new_rgb[2]*255))
        return new_color, True
    return hex_color, False

def main():
    accents_file = sys.argv[1]
    colors_file = sys.argv[2]
    
    with open(accents_file) as f:
        accents_data = json.load(f)
    with open(colors_file) as f:
        colors_data = json.load(f)
    
    # Get active border color (primary accent)
    active_hex = accents_data["accents"]["primary"]["color"]
    active_adjusted, _ = brighten_if_dark(active_hex)
    
    # Get inactive border color (surfaceContainer)
    inactive_hex = colors_data.get("surfaceContainer", "525264")
    inactive_adjusted, _ = brighten_if_dark(inactive_hex)
    
    # Output Lua command - strip # from final values
    active_hex_clean = active_adjusted.lstrip('#')
    inactive_hex_clean = inactive_adjusted.lstrip('#')
    
    lua_cmd = 'hl.config({ general = { col = { active_border = "rgba(' + active_hex_clean + 'FF)", inactive_border = "rgba(' + inactive_hex_clean + 'FF)" } } })'
    
    sys.stdout.write(lua_cmd)

if __name__ == "__main__":
    main()
