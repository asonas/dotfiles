local wezterm = require("wezterm")
local config = {}

if wezterm.target_triple == "aarch64-apple-darwin" then
	config.leader = { key = "j", mods = "CTRL", timeout_milliseconds = 1000 }
	config.keys = {
		{
			key = "v",
			mods = "LEADER|CTRL",
			action = wezterm.action.SplitPane({
				direction = "Right",
				size = { Percent = 50 },
			}),
		},
		{ key = "s", mods = "LEADER|CTRL", action = wezterm.action.SplitVertical },
		{
			key = "c",
			mods = "LEADER|CTRL",
			action = wezterm.action.SpawnTab("CurrentPaneDomain"),
		},
		{
			key = "p",
			mods = "LEADER|CTRL",
			action = wezterm.action.MoveTabRelative(-1),
		},
		{
			key = "n",
			mods = "LEADER|CTRL",
			action = wezterm.action.MoveTabRelative(1),
		},
		{
			key = "o",
			mods = "LEADER|CTRL",
			action = wezterm.action.RotatePanes("Clockwise"),
		},
		{ key = "w", mods = "LEADER|CTRL", action = wezterm.action.PaneSelect },
		{
			key = "i",
			mods = "LEADER|CTRL",
			action = wezterm.action.ActivatePaneDirection("Next"),
		},
	}
end
config.mouse_bindings = {
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = wezterm.action_callback(function(window, pane)
			local has_selection = window:get_selection_text_for_pane(pane) ~= ""
			if has_selection then
				window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
				window:perform_action(act.ClearSelection, pane)
			else
				window:perform_action(act({ PasteFrom = "Clipboard" }), pane)
			end
		end),
	},
}

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	config.keys = {
		{
			key = "c",
			mods = "CTRL|SHIFT",
			action = wezterm.action.CopyTo("ClipboardAndPrimarySelection"),
		},
		{
			key = "v",
			mods = "CTRL|SHIFT",
			action = wezterm.action.PasteFrom("Clipboard"),
		},
		{
			key = "v",
			mods = "CTRL",
			action = wezterm.action.PasteFrom("PrimarySelection"),
		},
		{
			key = "g",
			mods = "CTRL",
			action = wezterm.action.SendKey({ key = "Escape" }),
		},
		{
			key = "R",
			mods = "CTRL|SHIFT",
			action = wezterm.action.ReloadConfiguration,
		},
	}

	config.font = wezterm.font_with_fallback({ "SauceCodePro NF" })
else
	config.font = wezterm.font({
		family = "源ノ角ゴシック Code JP",
		weight = "Medium",
	})
	config.freetype_load_target = "Light"
	config.font_size = 13.0
	config.freetype_load_target = "HorizontalLcd"
	config.foreground_text_hsb = {
		hue = 1.0,
		saturation = 1.0,
		brightness = 0.9, -- default is 1.0
	}
end
config.window_background_gradient = { colors = { "#14191e" } }
config.bold_brightens_ansi_colors = "BrightAndBold"

config.colors = { foreground = "white" }
config.window_background_opacity = 0.92

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = wezterm.truncate_right(utils.basename(tab.active_pane.foreground_process_name), max_width)
	if title == "" then
		title = wezterm.truncate_right(
			utils.basename(utils.convert_home_dir(tab.active_pane.current_working_dir)),
			max_width
		)
	end
	return { { Text = tab.tab_index + 1 .. ":" .. title } }
end)
return config
