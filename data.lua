local default_gui = data.raw["gui-style"].default


data:extend{
  {
    type = "sprite",
    name = "tral_sprite_loco",
    filename = "__base__/graphics/icons/diesel-locomotive.png",
    width = 32,
    height = 32,
    scale = 1,
  },
}

default_gui["tral_toggle_button_with_alert"] = {
  type = "button_style",
  parent = "mod_gui_button",
  default_graphical_set = {
    base = {position = {136, 17}, corner_size = 8},
    shadow = default_dirt,
  },
  hovered_graphical_set = {
    base = {position = {170, 17}, corner_size = 8},
    shadow = default_dirt,
    glow = default_glow(default_glow_color, 0.5),
  },
  clicked_vertical_offset = 1,
  clicked_graphical_set = {
    base = {position = {187, 17}, corner_size = 8},
    shadow = default_dirt,
  },
}

default_gui["tral_transparent_frame"] = {
  type = "frame_style",
  use_header_filler = false,
  graphical_set = {
    base = {filename = "__Train_Alerts__/graphics/frame.png", position = {0, 0}, corner_size = 8},
    shadow = default_dirt,
  }
}

data:extend({{
	type = "custom-input",
	name = "tral-toggle-hotkey",
	key_sequence = "SHIFT + T",
	consuming = "none",
}})
