local wezterm = require("wezterm")
local config = wezterm.config_builder()
local action = wezterm.action

config.automatically_reload_config = true
config.enable_tab_bar = false
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"
config.window_padding = {
	left = "2cell",
	right = "2cell",
	top = "1cell",
	bottom = "1cell"
}
config.default_cursor_style = "BlinkingBar"
config.font = wezterm.font {
	family = "MesloLGS Nerd Font Mono",
	weight = "Medium",
	harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }, -- disable ligatures
}
config.font_size = 12
config.line_height = 1.2

local function scheme_for_appearance(appearance)
  if appearance:find "Dark" then
    return "Catppuccin Macchiato"
  else
    return "Catppuccin Latte"
  end
end

if wezterm.gui then
  config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())
else
  -- fallback in case wezterm.gui is not available (e.g., in CLI tools)
  config.color_scheme = "Catppuccin Macchiato"
end

-- 창 크기 지정
config.initial_rows = 40
config.initial_cols = 100

-- Pane 경계 강조
config.inactive_pane_hsb = {
  saturation = 1.0,
  brightness = 0.6,
}

-- Pane border 스타일 지정
config.window_frame = {
  active_titlebar_bg = "#1e1e2e", -- active border
  inactive_titlebar_bg = "#1e1e2e", -- inactive border
}
config.colors = {
  split = "#44475a", -- pane split border
}

config.keys = {
	{ key = 'd', mods = 'CMD|SHIFT', action = action.SplitVertical { domain = 'CurrentPaneDomain' } },
	{ key = 'd', mods = 'CMD', action = action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
	{ key = 'k', mods = 'CMD', action = action.ClearScrollback 'ScrollbackAndViewport' },
	{ key = 'w', mods = 'CMD', action = action.CloseCurrentPane { confirm = false } },
	{ key = 'w', mods = 'CMD|SHIFT', action = action.CloseCurrentTab { confirm = false } },
	{ key = 'LeftArrow', mods = 'CMD', action = action.SendString('\x01') },
	{ key = 'RightArrow', mods = 'CMD', action = action.SendString('\x05') },
	{ key = 'p', mods = 'CMD|SHIFT', action = action.ActivateCommandPalette },
	{
		key = "LeftArrow",
		mods = "OPT",
		action = wezterm.action.SendKey {
		key = "b",
		mods = "ALT",
		},
	},
	{
		key = "RightArrow",
		mods = "OPT",
		action = wezterm.action.SendKey {
		key = "f",
		mods = "ALT",
		},
	},
}

return config