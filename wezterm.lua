local wezterm = require("wezterm")

-- local ai_helper_plugin = wezterm.plugin.require("https://github.com/Michal1993r/ai-helper.wezterm")
local ai_helper_plugin = require("ai-helper-wezterm.plugin")
local ai_helper_config = {
	type = "google",
	api_key = "AIzaSyAFANlyazvGZDncmEA_Quc9ATInj2lS2kA",
	model = "gemini-2.5-flash",
	luarocks_path = "D:\\LuaRocks\\luarocks.exe",
	keybinding = {
		key = "i",
		mods = "ALT",
	},
	system_prompt = "You are an assistant that specializes in Windows command line, PowerShell, and WSL. "
		.. "You will be brief and to the point. If asked for commands, print them in a way that's easy to copy. "
		.. "Otherwise, just answer the question. Concatenate commands with && for cmd or ; for PowerShell where appropriate for ease of use.",
}

local act = wezterm.action

local config = wezterm.config_builder()

config.default_prog = { "C:\\Program Files\\PowerShell\\7\\pwsh.exe", "-NoLogo" }

config.launch_menu = {
	{ label = "PowerShell 7", args = { "C:\\Program Files\\PowerShell\\7\\pwsh.exe", "-NoLogo" } },
	{ label = "WSL Ubuntu", args = { "wsl.exe", "-d", "Ubuntu" } },
}

-- font configuration
local font_config = {
	family = "JetBrainsMono Nerd Font",
	weight = "Bold",
	size = 15,
	ligatures = { "calt=1", "clig=1", "liga=1", "zero", "ss01" },
	line_height = 1.1,
}

config.font = wezterm.font(font_config.family, { weight = font_config.weight })
config.font_size = font_config.size
config.harfbuzz_features = font_config.ligatures
config.line_height = font_config.line_height

-- color scheme configuration
local color_config = {
	scheme = "Catppuccin Mocha",
	-- alternative: "Tokyo Night"
}

config.color_scheme = color_config.scheme

-- keybinding configuration
local keys = {}

-- --- Tab Management ---
local tab_keys = {
	{ key = "t", mods = "ALT", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "ALT|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
	{ key = "LeftArrow", mods = "ALT", action = act.ActivateTabRelative(-1) },
	{ key = "RightArrow", mods = "ALT", action = act.ActivateTabRelative(1) },
}

-- tab by number (Alt+1..9)
local tab_number_keys = {
	{ key = "1", mods = "ALT", action = act.ActivateTab(0) },
	{ key = "2", mods = "ALT", action = act.ActivateTab(1) },
	{ key = "3", mods = "ALT", action = act.ActivateTab(2) },
	{ key = "4", mods = "ALT", action = act.ActivateTab(3) },
	{ key = "5", mods = "ALT", action = act.ActivateTab(4) },
	{ key = "6", mods = "ALT", action = act.ActivateTab(5) },
	{ key = "7", mods = "ALT", action = act.ActivateTab(6) },
	{ key = "8", mods = "ALT", action = act.ActivateTab(7) },
	{ key = "9", mods = "ALT", action = act.ActivateTab(8) },
}

-- --- Pane Management ---
local pane_keys = {
	{ key = "w", mods = "ALT", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "h", mods = "ALT", action = act.ActivatePaneDirection("Left") },
	{ key = "l", mods = "ALT", action = act.ActivatePaneDirection("Right") },
	{ key = "k", mods = "ALT", action = act.ActivatePaneDirection("Up") },
	{ key = "j", mods = "ALT", action = act.ActivatePaneDirection("Down") },
	{ key = "s", mods = "ALT", action = act.PaneSelect({ mode = "SwapWithActive" }) },
}

-- --- Splits ---
local split_keys = {
	{ key = "H", mods = "ALT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "V", mods = "ALT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
}

-- --- Pane Resizing ---
local resize_keys = {
	{ key = "LeftArrow", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Left", 3 }) },
	{ key = "RightArrow", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Right", 3 }) },
	{ key = "UpArrow", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Up", 2 }) },
	{ key = "DownArrow", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Down", 2 }) },
}

-- --- Configuration & Utilities ---
local config_keys = {
	{ key = "r", mods = "ALT", action = act.ReloadConfiguration },
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

-- combine all keybindings
for _, group in ipairs({ tab_keys, tab_number_keys, pane_keys, split_keys, resize_keys, config_keys }) do
	for _, key in ipairs(group) do
		table.insert(keys, key)
	end
end

config.keys = keys

-- ui configuration
local ui_config = {
	-- command palette
	command_palette = {
		rows = 7,
		font_size = 15,
		bg_color = "#44382D",
		fg_color = "#c4a389",
	},

	-- visual bell
	bell = {
		audible = "Disabled",
		visual = {
			target = "CursorColor",
			fade_in_function = "EaseIn",
			fade_in_duration_ms = 150,
			fade_out_function = "EaseOut",
			fade_out_duration_ms = 300,
		},
	},

	-- cursor and visual settings
	cursor = {
		thickness = 2,
		style = "SteadyBar",
	},

	-- window settings
	window = {
		close_confirmation = "NeverPrompt",
		decorations = "INTEGRATED_BUTTONS|RESIZE",
		padding = { left = 8, right = 8, top = 12, bottom = 8 },
		adjust_size_when_changing_font = false,
	},

	-- tab settings
	tab = {
		max_width = 60,
		use_fancy_tab_bar = false,
		show_new_tab_button = false,
		switch_to_last_active_when_closing = true,
	},

	-- pane settings
	pane = {
		inactive_hsb = { saturation = 1.0, brightness = 0.8 },
	},
}

-- general settings
local general_config = {
	bold_brightens_ansi_colors = "No",
	default_cwd = wezterm.home_dir,
	hyperlink_rules = wezterm.default_hyperlink_rules(),
	scrollback_lines = 10000,
}

-- apply command palette settings
config.command_palette_rows = ui_config.command_palette.rows
config.command_palette_font_size = ui_config.command_palette.font_size
config.command_palette_bg_color = ui_config.command_palette.bg_color
config.command_palette_fg_color = ui_config.command_palette.fg_color

-- apply bell settings
config.audible_bell = ui_config.bell.audible
config.visual_bell = ui_config.bell.visual

-- apply cursor settings
config.cursor_thickness = ui_config.cursor.thickness
config.default_cursor_style = ui_config.cursor.style

-- apply window settings
config.window_close_confirmation = ui_config.window.close_confirmation
config.window_decorations = ui_config.window.decorations
config.window_padding = ui_config.window.padding
config.adjust_window_size_when_changing_font_size = ui_config.window.adjust_size_when_changing_font

-- apply tab settings
config.tab_max_width = ui_config.tab.max_width
config.use_fancy_tab_bar = ui_config.tab.use_fancy_tab_bar
config.show_new_tab_button_in_tab_bar = ui_config.tab.show_new_tab_button
config.switch_to_last_active_tab_when_closing_tab = ui_config.tab.switch_to_last_active_when_closing

-- apply pane settings
config.inactive_pane_hsb = ui_config.pane.inactive_hsb

-- apply general settings
config.bold_brightens_ansi_colors = general_config.bold_brightens_ansi_colors
config.default_cwd = general_config.default_cwd
config.hyperlink_rules = general_config.hyperlink_rules
config.scrollback_lines = general_config.scrollback_lines

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

ai_helper_plugin.apply_to_config(config, ai_helper_config)

return config
