-- Hyprland Lua config



-- ---- MONITORS ----

hl.monitor({
output   = "",
mode     = "preferred",
position = "auto",
scale    = "1.0",
})


-- ---- MY PROGRAMS ----

local terminal    = "kitty"
local fileManager = "kitty -e yazi"
local browser     = "app.zen_browser.zen"
local menu        = "rofi -show drun -theme ~/.config/hypr/rofi/launcher.rasi"


-- ---- AUTOSTART ----

hl.on("hyprland.start", function()
hl.exec_cmd("dbus-update-activation-environment WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_RUNTIME_DIR QT_QPA_PLATFORMTHEME")

-- Load hyprpm plugins (ScrollOverview). Without this the plugin is only
-- loaded manually and its plugin.scrolloverview.* keys show up as config
-- errors.
hl.exec_cmd("hyprpm reload")

hl.exec_cmd("~/.config/hypr/scripts/wallpaper-watcher")
hl.exec_cmd("~/.config/hypr/scripts/matugen-wallpaper")

-- Launch the Waybar mode saved in ~/.local/state/waybar-mode (bare `waybar`
-- always started the floating config and ignored the selected mode).
hl.exec_cmd("~/.config/hypr/scripts/toggle-waybar.sh start")
hl.exec_cmd("dunst")
-- Clipboard history for the rofi clipboard menu (Mod+Shift+V).
hl.exec_cmd("~/.config/hypr/scripts/clipboard-watcher")
hl.exec_cmd("pgrep -x mpd >/dev/null || mpd")

end)


-- ---- ENVIRONMENT VARIABLES / QT / CURSOR ----

hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "KDE")


-- ---- LOOK AND FEEL ----

-- Border colours track the wallpaper theme so Hyprland, Waybar and Rofi
-- always show the same accent (accent files written by matugen-wallpaper).
local function theme_hex(file, key, fallback)
    local fh = io.open(file, "r")
    if not fh then return fallback end
    local body = fh:read("*a")
    fh:close()
    local hex = body:match('"' .. key .. '"%s*:%s*{[^}]*"color"%s*:%s*"(#[%da-fA-F]+)"')
        or body:match('"' .. key .. '"%s*:%s*"(#[%da-fA-F]+)"')
    if hex then return (hex:gsub("#", "")) end
    return fallback
end

local theme_dir = (os.getenv("HOME") or "") .. "/.cache/desktop-theme/"

-- Window borders are sharp neon, not muted tints: both use the wallpaper's
-- @neon-blue (the generated derivation shared with waybar and rofi), with
-- the inactive border pushed toward the theme background so unfocused
-- windows stay secondary but visible. scripts/pywal-borders computes the
-- same values on wallpaper changes -- keep the two in sync.
-- css_hex matches "@define-color key #hex;" in the generated waybar css;
-- accents.json cannot be used directly because it stores colours without
-- a leading '#', which made the old reader fall back to grey.
local function css_hex(file, key, fallback)
    local fh = io.open(file, "r")
    if not fh then return fallback end
    local body = fh:read("*a")
    fh:close()
    local hex = body:match("@define%-color " .. key .. "%s+(#[%da-fA-F]+)")
    if hex then return (hex:gsub("#", "")) end
    return fallback
end

local function theme_rgba(hex, blend)
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if blend then
        local bg = theme_hex(theme_dir .. "colors.json", "background", "101010")
        r = r + (tonumber(bg:sub(1, 2), 16) - r) * blend
        g = g + (tonumber(bg:sub(3, 4), 16) - g) * blend
        b = b + (tonumber(bg:sub(5, 6), 16) - b) * blend
    end
    return string.format("rgba(%02x%02x%02xFF)",
        math.min(255, math.floor(r + 0.5)),
        math.min(255, math.floor(g + 0.5)),
        math.min(255, math.floor(b + 0.5)))
end

local neon_border_hex      = css_hex(theme_dir .. "colors-waybar.css", "neon%-blue", "88c5fc")
local active_border_rgba   = theme_rgba(neon_border_hex)
local inactive_border_rgba = theme_rgba(neon_border_hex, 0.55)

-- Active window layout, switched by rofi/scripts/rofi_layout (Mod+L).
-- Read from the state file at config load so the choice survives config
-- reloads; unknown or missing values fall back to the default layout.
-- Keep this whitelist in sync with the script's layout list.
local function active_layout()
    local fh = io.open((os.getenv("HOME") or "") .. "/.local/state/hypr/layout", "r")
    if fh then
        local value = fh:read("*l")
        fh:close()
        if value == "scrolling" or value == "dwindle" or value == "master" or value == "monocle" then
            return value
        end
    end
    return "scrolling"
end

hl.config({
general = {
gaps_in  = 6,
gaps_out = 15,

    border_size = 2,

    col = {
        active_border   = active_border_rgba,
        inactive_border = inactive_border_rgba,
    },

    resize_on_border = false,
    allow_tearing = false,
    layout = active_layout(),
},

decoration = {
    rounding       = 14,
    rounding_power = 10,

    active_opacity   = 1.0,
    inactive_opacity = 1.0,

    shadow = {
        enabled      = true,
        range        = 32,
        render_power = 4,
        color        = 0xee000000,
    },

    blur = {
        enabled  = true,
        size     = 6,
        passes   = 3,
        vibrancy = 1,
    },
},

animations = {
    enabled = true,
},

------ Workspace Overview (ScrollOverview) ----

plugin = {
    scrolloverview = {
        gesture_distance = 300,
        scale = 0.5,
        workspace_gap = 100,
        layout = "vertical",
        wallpaper = 2,
        wallpaper_layer = "auto",
        blur = true,

        shadow = {
            enabled = true,
            range = 50,
        },
    },
},

})


-- ---- ANIMATIONS ----

hl.curve("easeOutQuint", {
type = "bezier",
points = { {0.23, 1}, {0.32, 1} }
})

hl.curve("easeInOutCubic", {
type = "bezier",
points = { {0.65, 0.05}, {0.36, 1} }
})

hl.curve("linear", {
type = "bezier",
points = { {0, 0}, {1, 1} }
})

hl.curve("almostLinear", {
type = "bezier",
points = { {0.5, 0.5}, {0.75, 1} }
})

hl.curve("quick", {
type = "bezier",
points = { {0.15, 0}, {0.1, 1} }
})

hl.curve("easy", {
type = "spring",
mass = 1,
stiffness = 238.1191,
dampening = 24.21279333,
})


hl.animation({
leaf = "windows",
enabled = true,
speed = 3.5,
bezier = "easeOutQuint"
})

hl.animation({
leaf = "windowsIn",
enabled = true,
speed = 3.5,
bezier = "easeOutQuint",
style = "popin 87%"
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 3.5,
    bezier = "easeOutQuint",
    style = "popin 87%"
})

hl.animation({
leaf = "fadeIn",
enabled = true,
speed = 1.6,
bezier = "easeOutQuint"
})

hl.animation({
leaf = "fadeOut",
enabled = true,
speed = 2.5,
bezier = "easeOutQuint"
})

hl.animation({
leaf = "fade",
enabled = true,
speed = 1.6,
bezier = "easeOutQuint"
})

hl.animation({
leaf = "layers",
enabled = true,
speed = 2,
bezier = "easeOutQuint"
})

hl.animation({
leaf = "layersIn",
enabled = true,
speed = 2,
bezier = "easeOutQuint",
style = "popin 87%"
})

hl.animation({
leaf = "layersOut",
enabled = true,
speed = 2,
bezier = "linear",
style = "popin 87%"
})

hl.animation({
leaf = "fadeLayersIn",
enabled = true,
speed = 1.8,
bezier = "almostLinear"
})

-- Rofi-specific layer animation
hl.layer_rule({
    name = "rofi-popin",
    match = { namespace = "^rofi$" },
    animation = "popin",
})


hl.animation({
leaf = "fadeLayersOut",
enabled = true,
speed = 1.6,
bezier = "almostLinear"
})

hl.animation({
leaf = "workspaces",
enabled = true,
speed = 0.7,
bezier = "easeOutQuint",
style = "slidevert"
})

hl.animation({
leaf = "workspacesIn",
enabled = true,
speed = 2,
bezier = "easeOutQuint",
style = "slidevert"
})

hl.animation({
leaf = "workspacesOut",
enabled = true,
speed = 2,
bezier = "easeOutQuint",
style = "slidevert"
})

hl.animation({
leaf = "zoomFactor",
enabled = false,
speed = 5,
bezier = "quick"
})


-- ---- LAYOUTS ---

hl.config({
dwindle = {
preserve_split = true,
},
})

hl.config({
master = {
new_status = "slave",
},
})

hl.config({
scrolling = {
fullscreen_on_one_column = true,
},
})

hl.config({
monocle = {},
})

-- ---- MISC ------

hl.config({
misc = {
force_default_wallpaper = 0,
disable_hyprland_logo = true,
},
})


-- ---- INPUT ----

hl.config({
input = {
kb_layout  = "us",
kb_variant = "",
kb_model   = "",
kb_options = "",
kb_rules   = "",

    follow_mouse = 1,

    sensitivity = -0.4,

    

    touchpad = {
        natural_scroll = true,
    },
},

})

hl.device({
    name = "syn1b8b:01-06cb:7da2-touchpad",
    sensitivity = 0.1,
})

hl.gesture({
fingers = 3,
direction = "horizontal",
action = "workspace"
})


-- ---- KEYBINDINGS ----

local mainMod = "SUPER"

-- Bar Toggle

hl.bind(
    mainMod .. " + SHIFT + B",
    hl.dsp.exec_cmd("~/.config/hypr/rofi/scripts/rofi_barstyle")
)

-- Matugen colour-mode preset (dark <-> light, applies to the current wallpaper)

hl.bind(
    mainMod .. " + S",
    hl.dsp.exec_cmd("~/.config/hypr/rofi/scripts/rofi_colormode")
)

-- Matugen colour-scheme preset (applies to the current wallpaper)

hl.bind(
    mainMod .. " + T",
    hl.dsp.exec_cmd("~/.config/hypr/rofi/scripts/rofi_schemetype")
)

-- Focus mode toggle (eye-candy <-> no-distraction)

hl.bind(
    mainMod .. " + A",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle-focus.sh")
)

-- Terminal / file manager / launcher / Music Player / Txt Editor

hl.bind(
mainMod .. " + Z",
hl.dsp.exec_cmd("app.zen_browser.zen")
)

hl.bind(
mainMod .. " + M",
hl.dsp.exec_cmd("kitty -e rmpc")
)

hl.bind(
mainMod .. " + SHIFT + F",
hl.dsp.exec_cmd("kitty -e yazi")
)

hl.bind(
mainMod .. " + E",
hl.dsp.exec_cmd(fileManager)
)

hl.bind(
mainMod .. " + Return",
hl.dsp.exec_cmd(terminal)
)

hl.bind(
mainMod .. " + D",
hl.dsp.exec_cmd(menu)
)

hl.bind(
mainMod .. " + SHIFT + N",
hl.dsp.exec_cmd("kitty -e nmtui")
)

-- Rofi menus

hl.bind(
mainMod .. " + X",
hl.dsp.exec_cmd("~/.config/hypr/rofi/scripts/rofi_powermenu")
)

hl.bind(
mainMod .. " + N",
hl.dsp.exec_cmd("kitty -e nmtui")
)

hl.bind(
mainMod .. " + C",
hl.dsp.exec_cmd("~/.config/hypr/rofi/scripts/rofi_notifications")
)

hl.bind(
mainMod .. " + B",
hl.dsp.exec_cmd("kitty -e bluetoothctl")
)

hl.bind(
mainMod .. " + SHIFT + S",
hl.dsp.exec_cmd("~/.config/hypr/rofi/scripts/rofi_screenshot")
)

hl.bind(
mainMod .. " + P",
hl.dsp.exec_cmd("~/.config/hypr/rofi/scripts/rofi_powerprofile")
)

hl.bind(
mainMod .. " + SHIFT + V",
hl.dsp.exec_cmd("~/.config/hypr/rofi/scripts/rofi_clipboard")
)

-- Wallpaper

hl.bind(
mainMod .. " + W",
hl.dsp.exec_cmd("~/.config/hypr/rofi/scripts/rofi_wallpaper")
)

-- Window management

hl.bind("SUPER + TAB", function()
    hl.plugin.scrolloverview.overview("toggle all")
end, {
    description = "Toggle ScrollOverview",
})

hl.bind(
mainMod .. " + Q",
hl.dsp.window.close()
)

hl.bind(
mainMod .. " + SHIFT + E",
hl.dsp.exit()
)

hl.bind(
mainMod .. " + SHIFT + C",
hl.dsp.exec_cmd("hyprctl reload")
)


hl.bind(
mainMod .. " + F",
hl.dsp.window.fullscreen()
)

-- Layout / split

hl.bind(
mainMod .. " + J",
hl.dsp.layout("togglesplit")
)

-- Rofi layout switcher (scrolling / dwindle / master / monocle)

hl.bind(
mainMod .. " + L",
hl.dsp.exec_cmd("~/.config/hypr/rofi/scripts/rofi_layout")
)

-- Float
hl.bind(mainMod .. " + SPACE", function()
    local window = hl.get_active_window()
    if not window then return end

    local monitor = hl.get_active_monitor()
    if not monitor then return end

    local was_tiled = not window.floating
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))

    if was_tiled then
        hl.dispatch(hl.dsp.window.resize({
            x = math.floor(monitor.width * 0.53),
            y = math.floor(monitor.height * 0.53),
            relative = false
        }))
        hl.dispatch(hl.dsp.window.center())
    end
end)

-- Focus

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))

-- Move windows

hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))

-- Workspaces

for i = 1, 8 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Workspace switching

hl.bind(mainMod .. " + O", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }))

-- Scratchpad
-- Scratchpad

hl.bind(
mainMod .. " + MINUS",
hl.dsp.workspace.toggle_special("scratchpad")
)

hl.bind(
mainMod .. " + SHIFT + MINUS",
hl.dsp.window.move({ workspace = "special:scratchpad" })
)

-- Mouse window movement / resizing

hl.bind(
mainMod .. " + mouse:272",
hl.dsp.window.drag(),
{ mouse = true }
)

hl.bind(
mainMod .. " + mouse:273",
hl.dsp.window.resize(),
{ mouse = true }
)

-- Volume

hl.bind(
"XF86AudioRaiseVolume",
hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
{ locked = true, repeating = true }
)

hl.bind(
"XF86AudioLowerVolume",
hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
{ locked = true, repeating = true }
)

hl.bind(
"XF86AudioMute",
hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
{ locked = true, repeating = true }
)

hl.bind(
"XF86AudioMicMute",
hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
{ locked = true, repeating = true }
)

-- Brightness

hl.bind(
"XF86MonBrightnessUp",
hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),
{ locked = true, repeating = true }
)

hl.bind(
"XF86MonBrightnessDown",
hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),
{ locked = true, repeating = true }
)

-- Media

hl.bind(
"XF86AudioNext",
hl.dsp.exec_cmd("playerctl next"),
{ locked = true }
)

hl.bind(
"XF86AudioPause",
hl.dsp.exec_cmd("playerctl play-pause"),
{ locked = true }
)

hl.bind(
"XF86AudioPlay",
hl.dsp.exec_cmd("playerctl play-pause"),
{ locked = true }
)

hl.bind(
"XF86AudioPrev",
hl.dsp.exec_cmd("playerctl previous"),
{ locked = true }
)


-- ---- WINDOWS AND WORKSPACES ----

hl.window_rule({
name = "suppress-maximize-events",
match = {
class = ".*",
},

suppress_event = "maximize",

})

hl.window_rule({
name = "fix-xwayland-drags",
match = {
class      = "^$",
title      = "^$",
xwayland   = true,
float      = true,
fullscreen = false,
pin        = false,
},

no_focus = true,

})



-- Hyprland-run

hl.window_rule({
name = "move-hyprland-run",
match = {
class = "hyprland-run",
},

move  = "20 monitor_h-120",
float = true,

})

-- HyprMod managed settings
require("hyprland-gui")
