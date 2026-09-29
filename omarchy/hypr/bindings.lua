-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

hl.unbind("SUPER + SHIFT + TAB")

-- Frees this for Ghostty's split-down binding.
hl.unbind("SUPER + SHIFT + D")

-- ---------------------------------------------------------------- macOS ---
--
-- macOS-style app shortcuts, layered onto Omarchy's Super-as-Cmd convention
-- (same mechanism as /usr/share/omarchy/default/hypr/bindings/clipboard.lua).

-- Splits the press into down/up around a timer: sending the shortcut
-- directly can leave key state stuck or repeating.
local function send_chord(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))

    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

-- Uses Omarchy's terminal tag from default/hypr/apps/terminals.lua. Dynamic
-- tags carry a trailing "*".
local function active_window_is_terminal()
  local window = hl.get_active_window()
  if not window then
    return false
  end

  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return true
    end
  end

  return false
end

-- Extra Shift in terminals: unshifted chords are readline editing keys
-- (CTRL+W is backward-kill-word).
local function app_chord(key)
  return function()
    if active_window_is_terminal() then
      send_chord("CTRL SHIFT", key)()
    else
      send_chord("CTRL", key)()
    end
  end
end

-- cmd+W closes tab, cmd+Q closes window.
hl.unbind("SUPER + W")
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
o.bind("SUPER + W", "Close tab", app_chord("W"))

-- cmd+T/cmd+N. Don't bind CTRL+T: SUPER+T sends it. Float toggle is SUPER+SHIFT+T.
hl.unbind("SUPER + T")
o.bind("SUPER + T", "New tab", app_chord("T"))
o.bind("SUPER + N", "New window", app_chord("N"))
o.bind("SUPER + SHIFT + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))

-- cmd+L focuses the address bar. Layout toggle is SUPER+SHIFT+L.
hl.unbind("SUPER + L")
o.bind("SUPER + L", "Focus address bar", send_chord("CTRL", "L"))
o.bind("SUPER + SHIFT + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

-- cmd+` cycles windows of the focused app.
o.bind("SUPER + GRAVE", "Cycle windows of this app", "$HOME/.local/bin/cycle-app-windows")

-- Window groups (tabbed containers) are unused here; unbinding frees these keys.
for _, bind in ipairs({
  "SUPER + G",
  "SUPER + ALT + G",
  "SUPER + ALT + LEFT",
  "SUPER + ALT + RIGHT",
  "SUPER + ALT + UP",
  "SUPER + ALT + DOWN",
  "SUPER + ALT + TAB",
  "SUPER + ALT + SHIFT + TAB",
  "SUPER + CTRL + LEFT",
  "SUPER + CTRL + RIGHT",
  "SUPER + ALT + mouse_down",
  "SUPER + ALT + mouse_up",
}) do
  hl.unbind(bind)
end

for index = 1, 5 do
  hl.unbind("SUPER + ALT + code:" .. tostring(index + 9))
end

-- Window overview (exposé), on the key the group bindings just vacated.
o.bind("SUPER + ALT + TAB", "Window overview", "omarchy-shell shell toggle community.window-overview '{}'")

-- cmd+TAB: cycle windows on the current workspace.
hl.unbind("SUPER + TAB")
hl.unbind("SUPER + CTRL + TAB")
hl.unbind("ALT + TAB")
hl.unbind("ALT + SHIFT + TAB")
o.bind("SUPER + TAB", "Switch window", hl.dsp.window.cycle_next())
-- Second binding: cycling alone changes focus without raising, so a floating
-- window can stay buried under another.
o.bind("SUPER + TAB", "Reveal active window on top", hl.dsp.window.bring_to_top())

-- Frees hotkeys duplicated by the app grid, or unused apps.
hl.unbind("SUPER + SHIFT + B")
hl.unbind("SUPER + SHIFT + A")
hl.unbind("SUPER + SHIFT + G")
hl.unbind("SUPER + SHIFT + O")
hl.unbind("SUPER + SHIFT + W")
-- Wrapping cycle; see omarchy/bin/workspace-cycle.
o.bind("SUPER + ALT + LEFT", "Previous workspace", "$HOME/.local/bin/workspace-cycle prev")
o.bind("SUPER + ALT + RIGHT", "Next workspace", "$HOME/.local/bin/workspace-cycle next")

-- Five workspaces, not ten: the bar widget's count is hardcoded to five.
-- Omarchy binds 1-10 as code:10 through code:19.
for workspace = 6, 10 do
  local key = "code:" .. tostring(workspace + 9)
  hl.unbind("SUPER + " .. key)
  hl.unbind("SUPER + SHIFT + " .. key)
  hl.unbind("SUPER + SHIFT + ALT + " .. key)
end
o.bind("SUPER + ALT + UP", "Toggle fullscreen", "omarchy-hyprland-window-tiled-fullscreen-toggle")

-- Scratchpad: a Quake-style drop-down over the current workspace.
hl.unbind("SUPER + RETURN")
hl.unbind("SUPER + SHIFT + RETURN")
hl.unbind("SUPER + S")
hl.unbind("SUPER + ALT + S")

hl.unbind("SUPER + ALT + RETURN")
o.bind("SUPER + RETURN", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + SHIFT + RETURN", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- ------------------------------------------------------------ app grid ---
--
-- Hermes layout from macOS (same letters). Focuses the app if running,
-- launches it if not. Scratchpad windows are skipped (has its own key).

hl.unbind("SUPER + ALT + K")
hl.unbind("SUPER + ALT + COMMA")

local function app(key, name, pattern, launch)
  o.bind("SUPER + ALT + " .. key, name, "$HOME/.local/bin/app-focus " .. pattern .. " '" .. launch .. "'")
end

app("I", "Plex", "app.plex.tv", "omarchy-launch-webapp https://app.plex.tv/desktop")
app("U", "Plexamp", "Plexamp", "uwsm-app -- plexamp")
app("H", "Slack", "Slack", "uwsm-app -- slack")
app("J", "Ghostty", "ghostty", "uwsm-app -- ghostty")
app("K", "Neovide", "neovide", "uwsm-app -- neovide")
app("L", "Gemini", "gemini.google.com", "omarchy-launch-webapp https://gemini.google.com")
app("SEMICOLON", "Browser", "firefox", "omarchy-launch-browser")
app("M", "Gmail", "mail.google.com", "omarchy-launch-webapp https://mail.google.com")
app("COMMA", "Calendar", "calendar.google.com", "omarchy-launch-webapp https://calendar.google.com")
