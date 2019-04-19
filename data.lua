defs = require("script.defines")
require("prototypes.style")

data:extend({{
	type = "custom-input",
	name = defs.names.controls.toggle_hotkey,
	key_sequence = "SHIFT + T",
	consuming = "none",
}})

data:extend({{
  type = "shortcut",
  name = defs.names.controls.toggle_shortcut,
  order = "a[tral-toggle-shortcut]",
  action = "lua",
  localised_name = {"shortcut.tral-toggle"},
  style = "default",
  technology_to_unlock = "railway",
  toggleable = true,
  associated_control_input = defs.names.controls.toggle_hotkey,
  icon =
  {
    filename = defs.spritepath.shortcut_x32,
    priority = "extra-high-no-scale",
    size = 32,
    scale = 1,
    flags = {"icon"}
  },
  disabled_icon =
  {
    filename = defs.spritepath.shortcut_x32_bw,
    priority = "extra-high-no-scale",
    size = 32,
    scale = 1,
    flags = {"icon"}
  },
  small_icon =
  {
    filename = defs.spritepath.shortcut_x24,
    size = 24,
    scale = 1,
    flags = {"icon"}
  },
  disabled_small_icon =
  {
    filename = defs.spritepath.shortcut_x24_bw,
    priority = "extra-high-no-scale",
    size = 24,
    scale = 1,
    flags = {"icon"}
  },
}})
