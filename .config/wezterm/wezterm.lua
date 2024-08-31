local wezterm = require("wezterm")
local config = {}

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

local function is_ssh()
	local ssh_connection = os.getenv("SSH_CONNECTION") or ""
	return ssh_connection ~= ""
end

-- keyconfig
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
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
		{
			key = "c",
			mods = "ALT",
			action = wezterm.action.CopyTo("ClipboardAndPrimarySelection"),
		},
		{
			key = "v",
			mods = "ALT",
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
else
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

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	config.font = wezterm.font_with_fallback({ "SauceCodePro NF" })
	config.unix_domains = {
  {
    name = 'wsl',
    -- Override the default path to match the default on the host win32
    -- filesystem.  This will allow the host to connect into the WSL
    -- container.
    socket_path = '/mnt/c/Users/asonas/.local/share/wezterm/sock',
    -- NTFS permissions will always be "wrong", so skip that check
    skip_permissions_check = true,
  },
}
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

config.initial_rows = 60
config.initial_cols = 200
config.adjust_window_size_when_changing_font_size = false
config.window_decorations = "RESIZE"
wezterm.on('gui-startup', function(cmd)
  local _, _, window = wezterm.mux.spawn_window(cmd or {})
  window:gui_window():set_position(0, 0) -- 起動時にウィンドウを指定した位置に移動
end)

if wezterm.target_triple == "aarch64-apple-darwin" then
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
end
return config
