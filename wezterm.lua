local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

config.default_prog = { "C:\\Program Files\\PowerShell\\7\\pwsh.exe", "-NoLogo" }

config.launch_menu = {
	{ label = "PowerShell 7", args = { "C:\\Program Files\\PowerShell\\7\\pwsh.exe", "-NoLogo" } },
	{ label = "WSL Ubuntu", args = { "wsl.exe", "-d", "Ubuntu" } },
}

local font = "JetBrainsMono Nerd Font"
config.font = wezterm.font(font, { weight = "Bold" })

-- enable font ligatures
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1", "zero", "ss01" }

-- config.color_scheme = "Tokyo Night"
config.color_scheme = "Catppuccin Mocha"

config.keys = {
	-- --- Tabs ---
	{ key = "t", mods = "ALT", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "ALT|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
	{ key = "LeftArrow", mods = "ALT", action = act.ActivateTabRelative(-1) },
	{ key = "RightArrow", mods = "ALT", action = act.ActivateTabRelative(1) },

	-- Tab by number (Alt+1..9)
	{ key = "1", mods = "ALT", action = act.ActivateTab(0) },
	{ key = "2", mods = "ALT", action = act.ActivateTab(1) },
	{ key = "3", mods = "ALT", action = act.ActivateTab(2) },
	{ key = "4", mods = "ALT", action = act.ActivateTab(3) },
	{ key = "5", mods = "ALT", action = act.ActivateTab(4) },
	{ key = "6", mods = "ALT", action = act.ActivateTab(5) },
	{ key = "7", mods = "ALT", action = act.ActivateTab(6) },
	{ key = "8", mods = "ALT", action = act.ActivateTab(7) },
	{ key = "9", mods = "ALT", action = act.ActivateTab(8) },

	-- --- Panes ---
	{ key = "w", mods = "ALT", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "h", mods = "ALT", action = act.ActivatePaneDirection("Left") },
	{ key = "l", mods = "ALT", action = act.ActivatePaneDirection("Right") },
	{ key = "k", mods = "ALT", action = act.ActivatePaneDirection("Up") },
	{ key = "j", mods = "ALT", action = act.ActivatePaneDirection("Down") },

	-- --- Splits ---
	{ key = "H", mods = "ALT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "V", mods = "ALT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- --- Reload config ---
	{ key = "r", mods = "ALT", action = act.ReloadConfiguration },

	-- Open wezterm config file in neovide editor
	{
		key = ",",
		mods = "CTRL",
		action = wezterm.action.SpawnCommandInNewTab({
			cwd = os.getenv("WEZTERM_CONFIG_DIR"),
			set_environment_variables = {
				TERM = "screen-256color",
			},
			args = {
				"neovide.exe",
				os.getenv("WEZTERM_CONFIG_FILE"),
			},
		}),
	},
}

-- Command Palette
config.command_palette_rows = 7
config.command_palette_font_size = 15
config.command_palette_bg_color = "#44382D"
config.command_palette_fg_color = "#c4a389"

-- Visual bell
config.audible_bell = "Disabled"
config.visual_bell = {
	target = "CursorColor",
	fade_in_function = "EaseIn",
	fade_in_duration_ms = 150,
	fade_out_function = "EaseOut",
	fade_out_duration_ms = 300,
}

-- Misc
config.adjust_window_size_when_changing_font_size = false
config.bold_brightens_ansi_colors = "No"
config.cursor_thickness = 2
config.default_cursor_style = "SteadyBar"
config.default_cwd = wezterm.home_dir
config.font_size = 15
config.hyperlink_rules = wezterm.default_hyperlink_rules()
config.inactive_pane_hsb = { saturation = 1.0, brightness = 0.8 }
config.line_height = 1.1
config.scrollback_lines = 10000
config.show_new_tab_button_in_tab_bar = false
config.switch_to_last_active_tab_when_closing_tab = true
config.tab_max_width = 60
config.use_fancy_tab_bar = false
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_padding = { left = 8, right = 8, top = 12, bottom = 8 }

local function get_current_working_dir(tab)
	local current_dir_uri = tab.active_pane and tab.active_pane.current_working_dir or ""
	local current_dir_path = current_dir_uri:gsub("file://", "")
	local home_dir_path = os.getenv("USERPROFILE")
	if current_dir_path == home_dir_path then
		return "."
	end
	return string.gsub(current_dir_path, "(.*[/\\])(.*)", "%2")
end

-- Set tab title to the one that was set via `tab:set_title()`
-- or fall back to the current working directory as a title
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local index = tonumber(tab.tab_index) + 1
	local custom_title = tab.tab_title
	local title = get_current_working_dir(tab)

	if custom_title and #custom_title > 0 then
		title = custom_title
	end

	return string.format("  %s•%s  ", index, title)
end)

-- Set window title to the current working directory
wezterm.on("format-window-title", function(tab, pane, tabs, panes, config)
	return get_current_working_dir(tab)
end)

return config
