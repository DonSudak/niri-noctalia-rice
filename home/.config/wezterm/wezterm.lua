local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Noctalia writes colors/Noctalia.toml via templates — do not hardcode palette here
config.color_scheme_dirs = { wezterm.config_dir .. '/colors' }
config.color_scheme = "Noctalia"

config.default_prog = { '/usr/bin/fish' }

config.font = wezterm.font('JetBrainsMono Nerd Font Mono')
config.font_size = 13

config.enable_wayland = false

config.window_decorations = 'RESIZE'
config.window_background_opacity = 0.95

config.hide_tab_bar_if_only_one_tab = true
config.scrollback_lines = 10000
config.hyperlink_rules = wezterm.default_hyperlink_rules()

return config
