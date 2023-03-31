local wezterm = require 'wezterm'
local config = {}

config.keys = {
    {
      key = 'C',
      mods = 'CTRL',
      action = wezterm.action.CopyTo 'ClipboardAndPrimarySelection',
    },
    {
      key = 'V',
      mods = 'CTRL',
      action = wezterm.action.PasteFrom 'Clipboard',
    },
    {
      key = 'V',
      mods = 'CTRL',
      action = wezterm.action.PasteFrom 'PrimarySelection',
    },
    {
      key = 'R',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.ReloadConfiguration,
    },
}

config.font = wezterm.font 'SauceCodePro Nerd Font'

config.color_scheme = 'Solarized Darcula'

return config
