local wezterm = require 'wezterm'

return {
  keys = {
    {
      key = 'C',
      mods = 'CTRL',
      action = wezterm.action.CopyTo 'ClipboardAndPrimarySlection',
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
  },
}
