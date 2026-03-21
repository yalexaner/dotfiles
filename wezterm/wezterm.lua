local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action
local is_windows = wezterm.target_triple:find("windows")

-- shell
if is_windows then
	config.default_prog = { "wsl.exe", "-d", "Ubuntu" }
end

config.launch_menu = is_windows and {
	{ label = "PowerShell 7", args = { "C:\\Program Files\\PowerShell\\7\\pwsh.exe", "-NoLogo" } },
	{ label = "WSL Ubuntu", args = { "wsl.exe", "-d", "Ubuntu" } },
} or {
	{ label = "Zsh", args = { "/bin/zsh", "-l" } },
	{ label = "Bash", args = { "/bin/bash", "-l" } },
}

-- font
config.font = wezterm.font("JetBrainsMono Nerd Font", { weight = "Bold" })
config.font_size = 15
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1", "zero", "ss01" }
config.line_height = 1.1

-- color scheme
config.color_scheme = "Catppuccin Mocha"

-- cursor
config.cursor_thickness = 2
config.default_cursor_style = "SteadyBar"

-- window
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_padding = { left = 8, right = 8, top = 12, bottom = 8 }
config.adjust_window_size_when_changing_font_size = false

-- tab bar
config.tab_max_width = 60
config.use_fancy_tab_bar = false
config.show_new_tab_button_in_tab_bar = is_windows and true or false
config.switch_to_last_active_tab_when_closing_tab = true

-- panes
config.inactive_pane_hsb = { saturation = 1.0, brightness = 0.8 }

-- command palette
config.command_palette_rows = 7
config.command_palette_font_size = 15
config.command_palette_bg_color = "#44382D"
config.command_palette_fg_color = "#c4a389"

-- bell
config.audible_bell = "Disabled"
config.visual_bell = {
	target = "CursorColor",
	fade_in_function = "EaseIn",
	fade_in_duration_ms = 150,
	fade_out_function = "EaseOut",
	fade_out_duration_ms = 300,
}

-- general
config.bold_brightens_ansi_colors = "No"
config.default_cwd = wezterm.home_dir
config.hyperlink_rules = wezterm.default_hyperlink_rules()
config.scrollback_lines = 10000

config.quick_select_patterns = {
	[[([^:\s]+\.(?:img|zip))]],
}

-- keybindings
config.keys = {
	-- tab management
	{ key = "t", mods = "ALT", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "ALT|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
	{ key = "LeftArrow", mods = "ALT", action = act.ActivateTabRelative(-1) },
	{ key = "RightArrow", mods = "ALT", action = act.ActivateTabRelative(1) },

	-- tab by number (alt+1..9)
	{ key = "1", mods = "ALT", action = act.ActivateTab(0) },
	{ key = "2", mods = "ALT", action = act.ActivateTab(1) },
	{ key = "3", mods = "ALT", action = act.ActivateTab(2) },
	{ key = "4", mods = "ALT", action = act.ActivateTab(3) },
	{ key = "5", mods = "ALT", action = act.ActivateTab(4) },
	{ key = "6", mods = "ALT", action = act.ActivateTab(5) },
	{ key = "7", mods = "ALT", action = act.ActivateTab(6) },
	{ key = "8", mods = "ALT", action = act.ActivateTab(7) },
	{ key = "9", mods = "ALT", action = act.ActivateTab(8) },

	-- pane management
	{ key = "w", mods = "ALT", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "h", mods = "ALT", action = act.ActivatePaneDirection("Left") },
	{ key = "l", mods = "ALT", action = act.ActivatePaneDirection("Right") },
	{ key = "k", mods = "ALT", action = act.ActivatePaneDirection("Up") },
	{ key = "j", mods = "ALT", action = act.ActivatePaneDirection("Down") },
	{ key = "s", mods = "ALT", action = act.PaneSelect({ mode = "SwapWithActive" }) },

	-- splits
	{ key = "H", mods = "ALT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "V", mods = "ALT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- pane resizing
	{ key = "LeftArrow", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Left", 3 }) },
	{ key = "RightArrow", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Right", 3 }) },
	{ key = "UpArrow", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Up", 2 }) },
	{ key = "DownArrow", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Down", 2 }) },

	-- shell passthrough (ctrl+f and ctrl+r reach the shell for psreadline/fzf)
	{ key = "f", mods = "CTRL", action = act.SendKey({ key = "f", mods = "CTRL" }) },
	{ key = "r", mods = "CTRL", action = act.SendKey({ key = "r", mods = "CTRL" }) },

	-- config reload
	{ key = "r", mods = "ALT", action = act.ReloadConfiguration },
}

-- tab/window title: show current working directory
local function get_current_working_dir(tab)
	local current_dir_uri = tab.active_pane and tab.active_pane.current_working_dir or ""
	local function normalize_path(p)
		if not p then return "" end
		p = p:gsub("\\", "/")
		return string.lower(p)
	end
	local current_dir_path = normalize_path(current_dir_uri:gsub("file://", ""))
	local home_dir_path = normalize_path(
		(is_windows and os.getenv("USERPROFILE")) or os.getenv("HOME") or wezterm.home_dir
	)
	if current_dir_path == home_dir_path then
		return "."
	end
	return string.gsub(current_dir_path, "(.*[/\\])(.*)", "%2")
end

wezterm.on("format-tab-title", function(tab)
	local index = tonumber(tab.tab_index) + 1
	local custom_title = tab.tab_title
	local title = get_current_working_dir(tab)

	if custom_title and #custom_title > 0 then
		title = custom_title
	end

	return string.format("  %s•%s  ", index, title)
end)

wezterm.on("format-window-title", function(tab)
	return get_current_working_dir(tab)
end)

return config
