local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.default_prog = { "C:\\Program Files\\PowerShell\\7\\pwsh.exe", "-NoLogo" }

config.launch_menu = {
	{ label = "PowerShell 7", args = { "C:\\Program Files\\PowerShell\\7\\pwsh.exe", "-NoLogo" } },
	{ label = "WSL Ubuntu", args = { "wsl.exe", "-d", "Ubuntu" } },
}

config.font = wezterm.font("JetBrainsMono Nerd Font", { weight = "Bold" })

-- set the font
--[[
local font = "JetBrainsMono Nerd Font"
config.font = wezterm.font(font)
config.font_rules = {
	{
		intensity = "Bold",
		font = wezterm.font(font, { weight = "Bold" }),
	},
}
]]

-- enable font ligatures
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1", "zero", "ss01" }

-- Colors
config.color_scheme = "Squirrelsong Dark"

config.window_frame = {
	font = wezterm.font({ family = font, weight = "Bold" }),
	font_size = 15,
	-- Fancy tab bar
	active_titlebar_bg = "#574131",
	inactive_titlebar_bg = "#352a21",
}

-- Command Palette
config.command_palette_rows = 7
config.command_palette_font_size = 15
config.command_palette_bg_color = "#44382D"
config.command_palette_fg_color = "#c4a389"

-- Hot keys
config.keys = {
	-- Make Page up/down work
	{ key = "PageUp", action = wezterm.action.ScrollByPage(-1) },
	{ key = "PageDown", action = wezterm.action.ScrollByPage(1) },

	-- Pane splitting
	{
		key = "d",
		mods = "CTRL",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "w",
		mods = "CTRL",
		action = wezterm.action.CloseCurrentPane({ confirm = false }),
	},

	-- Switch between tabs
	{
		key = "LeftArrow",
		mods = "CTRL|ALT",
		action = wezterm.action.ActivateTabRelative(-1),
	},
	{
		key = "RightArrow",
		mods = "CTRL|ALT",
		action = wezterm.action.ActivateTabRelative(1),
	},

	-- Switch between panes
	{
		key = "LeftArrow",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Prev"),
	},
	{
		key = "RightArrow",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Next"),
	},

	-- Jump word to the left
	{
		key = "LeftArrow",
		mods = "ALT",
		action = wezterm.action.SendKey({ key = "b", mods = "ALT" }),
	},
	-- Jump word to the right
	{
		key = "RightArrow",
		mods = "ALT",
		action = wezterm.action.SendKey({ key = "f", mods = "ALT" }),
	},

	-- Go to beginning of line
	{
		key = "LeftArrow",
		mods = "CTRL",
		action = wezterm.action.SendKey({
			key = "a",
			mods = "CTRL",
		}),
	},
	-- Go to end of line
	{
		key = "RightArrow",
		mods = "CTRL",
		action = wezterm.action.SendKey({ key = "e", mods = "CTRL" }),
	},
	-- Delete line to the left of the cursor
	-- TODO: It actually deletes the whole line, but it's close enough
	{
		key = "Backspace",
		mods = "CTRL",
		action = wezterm.action.SendKey({ key = "u", mods = "CTRL" }),
	},

	-- Case-insensitive search
	{
		key = "f",
		mods = "CTRL",
		action = wezterm.action.Search({ CaseInSensitiveString = "" }),
	},

	-- Open WezTerm config file quickly
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

	-- Disable some default hotkeys
	{
		key = "Enter",
		mods = "ALT",
		action = wezterm.action.DisableDefaultAssignment,
	},

	-- Rename tab title
	{
		key = "R",
		mods = "CTRL|SHIFT",
		action = wezterm.action.PromptInputLine({
			description = "Enter new name for tab",
			action = wezterm.action_callback(function(window, _, line)
				-- line will be `nil` if they hit escape without entering anything
				-- An empty string if they just hit enter
				-- Or the actual line of text they wrote
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
}

-- Mouse
config.mouse_bindings = {
	-- Change the default click behavior so that it only selects
	-- text and doesn't open hyperlinks
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"),
	},

	-- Open links on CTRL+click
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
}

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

--- 8< -- 8< ---

return config
