local wezterm = require("wezterm")
local config = {}

config.leader = { key = "j", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	{
		key = "v",
		mods = "LEADER|CTRL",
		action = wezterm.action.SplitPane {
			direction = "Right",
			size = { Percent = 50 }
		}
	},
	{
		key = "s",
		mods = "LEADER|CTRL",
		action = wezterm.action.SplitVertical
	},
	{
		key = "c",
		mods = "LEADER|CTRL",
		action = wezterm.action.SpawnTab 'CurrentPaneDomain'
	},
	{
		key = "p",
		mods = "LEADER|CTRL",
		action = wezterm.action.MoveTabRelative(-1)
	},
	{
		key = "n",
		mods = "LEADER|CTRL",
		action = wezterm.action.MoveTabRelative(1)
	},
	{
		key = "o",
		mods = "LEADER|CTRL",
		action = wezterm.action.RotatePanes 'Clockwise'
	},
	{
		key = "w",
		mods = "LEADER|CTRL",
		action = wezterm.action.PaneSelect
	},
	{
		key = "i",
		mods = "LEADER|CTRL",
		action = wezterm.action.ActivatePaneDirection 'Next'
	},
}

if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
	config.keys = {
		{
			key = "c",
			mods = "CTRL",
			action = wezterm.action.CopyTo("ClipboardAndPrimarySelection"),
		},
		{
			key = "v",
			mods = "CTRL",
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

	config.font = wezterm.font_with_fallback({
		"SauceCodePro NF",
	})
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
config.window_background_gradient = {
	colors = { '#14191e' },
}
config.bold_brightens_ansi_colors = "BrightAndBold"

config.colors = {
	foreground = 'white',

}
config.window_background_opacity = 0.92
return config
