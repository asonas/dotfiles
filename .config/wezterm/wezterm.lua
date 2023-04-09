local wezterm = require 'wezterm'
local config = {}

config.keys = {
    {
      key = 'c',
      mods = 'CTRL',
      action = wezterm.action.CopyTo 'ClipboardAndPrimarySelection',
    },
    {
      key = 'v',
      mods = 'CTRL',
      action = wezterm.action.PasteFrom 'Clipboard',
    },
    {
      key = 'v',
      mods = 'CTRL',
      action = wezterm.action.PasteFrom 'PrimarySelection',
    },
    {
      key = 'g',
      mods = 'CTRL',
      action = wezterm.action.SendKey { key = 'Escape' },
    },
    {
      key = 'R',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.ReloadConfiguration,
    },
}

config.font = wezterm.font_with_fallback {
  'SauceCodePro NF',
  'SauceCodePro Nerd Font',
}

config.color_scheme = 'Solarized Darcula'

return config
