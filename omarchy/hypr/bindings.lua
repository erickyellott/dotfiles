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

-- SUPER+SHIFT+TAB was Omarchy's "Previous workspace"; that job belongs to
-- SUPER+ALT+LEFT now, so the key is left free. Window overview moved to
-- SUPER+ALT+TAB, bound further down -- it has to come after the group unbinds,
-- which would otherwise strip it right back off.
hl.unbind("SUPER + SHIFT + TAB")

-- Let SUPER+SHIFT+D reach Ghostty (split down). Was: Docker TUI.
hl.unbind("SUPER + SHIFT + D")

-- ---------------------------------------------------------------- macOS ---
--
-- Omarchy's own line is that Super replaces Cmd, and it already ships
-- SUPER+C/X/V as universal clipboard keys. These extend that to the rest of
-- the app shortcuts, using the same mechanism as
-- /usr/share/omarchy/default/hypr/bindings/clipboard.lua.

-- send_shortcut can leave synthetic key state stuck or repeating, so split the
-- press into down/up around a timer. See hyprwm/Hyprland#14099.
local function send_chord(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))

    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

-- Omarchy tags terminals in default/hypr/apps/terminals.lua, so lean on that
-- rather than keeping a second list of window classes here. Dynamic tags carry
-- a trailing "*".
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

-- Terminals put tab and window shortcuts behind an extra Shift, because the
-- unshifted chords are readline editing keys: CTRL+W is backward-kill-word.
local function app_chord(key)
  return function()
    if active_window_is_terminal() then
      send_chord("CTRL SHIFT", key)()
    else
      send_chord("CTRL", key)()
    end
  end
end

-- cmd+W closes the tab, cmd+Q the window. Omarchy binds SUPER+W to close the
-- whole window, hence the unbind.
hl.unbind("SUPER + W")
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
o.bind("SUPER + W", "Close tab", app_chord("W"))

-- cmd+T and cmd+N. SUPER+T was floating/tiling, which moves to SUPER+SHIFT+T.
-- CTRL+T is not an option for it: SUPER+T *sends* CTRL+T, so the compositor
-- would intercept its own synthetic keystroke.
hl.unbind("SUPER + T")
o.bind("SUPER + T", "New tab", app_chord("T"))
o.bind("SUPER + N", "New window", app_chord("N"))
o.bind("SUPER + SHIFT + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))

-- cmd+L focuses the address bar. Plain CTRL+L, not the terminal-shifted
-- variant app_chord uses: CTRL+L in a shell clears the screen, which is the
-- right thing for that key anyway. The layout toggle moves to SUPER+SHIFT+L --
-- CTRL+L is not available for it, since SUPER+L *sends* CTRL+L and the
-- compositor would catch its own synthetic keystroke.
hl.unbind("SUPER + L")
o.bind("SUPER + L", "Focus address bar", send_chord("CTRL", "L"))
o.bind("SUPER + SHIFT + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

-- cmd+` cycles windows of the focused app. ALT+TAB already cycles all windows,
-- which is close enough to cmd+TAB, so that one is left alone.
o.bind("SUPER + GRAVE", "Cycle windows of this app", "$HOME/.local/bin/cycle-app-windows")

-- Window groups (tabbed containers) are unused here, so the whole family goes.
-- That frees four arrows, SUPER+G, and SUPER+ALT+1..5, which otherwise reads
-- confusingly next to SUPER+1..5 for workspaces.
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

-- cmd+TAB: cycle windows on the current workspace. SUPER+TAB was a second way
-- to reach the next workspace, which SUPER+ALT+RIGHT already does -- and it
-- kept firing when the macOS reflex wanted app switching. ALT+TAB still works.
hl.unbind("SUPER + TAB")
hl.unbind("SUPER + CTRL + TAB")
-- ALT+TAB did the same job, and carried a second stacked binding that raised
-- the window as well. SUPER+TAB is the one the muscle memory reaches for.
hl.unbind("ALT + TAB")
hl.unbind("ALT + SHIFT + TAB")
o.bind("SUPER + TAB", "Switch window", hl.dsp.window.cycle_next())
-- Second stacked binding, as Omarchy had on ALT+TAB: cycling alone changes
-- focus without raising, so a floating window can stay buried under another.
o.bind("SUPER + TAB", "Reveal active window on top", hl.dsp.window.bring_to_top())

-- Duplicate of the app grid, or apps not used here. Omarchy drops an app's
-- hotkey when the app is uninstalled, so these only need unbinding while the
-- package is still around.
hl.unbind("SUPER + SHIFT + B")
hl.unbind("SUPER + SHIFT + A")
hl.unbind("SUPER + SHIFT + G")
hl.unbind("SUPER + SHIFT + O")
hl.unbind("SUPER + SHIFT + W")
-- Neither built-in relative form works here: "e" skips empty workspaces, and
-- "r" includes them but counts past the last one into 5, 6, ... See the script.
o.bind("SUPER + ALT + LEFT", "Previous workspace", "$HOME/.local/bin/workspace-cycle prev")
o.bind("SUPER + ALT + RIGHT", "Next workspace", "$HOME/.local/bin/workspace-cycle next")

-- Five workspaces, not ten -- five is what the bar widget shows, and its count
-- is hardcoded in the plugin. Omarchy binds 1-10 as code:10 through code:19.
for workspace = 6, 10 do
  local key = "code:" .. tostring(workspace + 9)
  hl.unbind("SUPER + " .. key)
  hl.unbind("SUPER + SHIFT + " .. key)
  hl.unbind("SUPER + SHIFT + ALT + " .. key)
end
o.bind("SUPER + ALT + UP", "Toggle fullscreen", "omarchy-hyprland-window-tiled-fullscreen-toggle")

-- The scratchpad is a Quake-style drop-down over the current workspace, and
-- it is where the long-lived terminal session lives. SUPER+RETURN was the
-- terminal launcher and SUPER+SHIFT+RETURN the browser; both are now reachable
-- from the app grid below, so the Return pair is better spent here.
-- Omarchy's own SUPER+S / SUPER+ALT+S pair is dropped: one way in is enough.
hl.unbind("SUPER + RETURN")
hl.unbind("SUPER + SHIFT + RETURN")
hl.unbind("SUPER + S")
hl.unbind("SUPER + ALT + S")

-- Tmux is unused here; this launched a terminal attached to a session Omarchy
-- hardcodes as "Work".
hl.unbind("SUPER + ALT + RETURN")
o.bind("SUPER + RETURN", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + SHIFT + RETURN", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- ------------------------------------------------------------ app grid ---
--
-- The Hermes layout from macOS, same letters so the muscle memory carries,
-- pointed at whatever fills that role here. Focus if running, launch if not.
-- Scratchpad windows are skipped: that has its own key.

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
