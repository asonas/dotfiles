local wezterm = require("wezterm")
local config = {}


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
     brightness = 0.9,  -- default is 1.0
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
