local default_gui = data.raw["gui-style"].default
local log2 = require("__OpteraLib__.script.logger")()
local WIDTH = {50, 200, 50}
local TOT_WIDTH = 325

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
  left_padding = 4,
  right_padding = 4,
  graphical_set = {
    base = {filename = "__Train_Alerts__/graphics/gui.png", position = {0, 17}, corner_size = 8},
    shadow = default_dirt,
  }
}

local function rounded_button_glow(tint_value)
  return
  {
    filename = "__Train_Alerts__/graphics/gui.png",
    position = {51, 17},
    corner_size = 16,
    tint = tint_value,
    top_outer_border_shift = 4,
    bottom_outer_border_shift = -4,
    left_outer_border_shift = 4,
    right_outer_border_shift = -4,
    draw_type = "outer"
  }
end
local function rounded_button_graphical_set(x, y, glow, size)
  size = size or 8
  if glow then
    glow = rounded_button_glow(default_glow_color)
  end
  return {
    base = {
      filename = "__Train_Alerts__/graphics/gui.png",
      position = {x, y},
      corner_size = size
    },
    shadow = rounded_button_glow(default_dirt_color),
    glow = glow,
  }

end


default_gui["tral_button_row"] = {
  type = "button_style",
  horizontal_align = "left",
  left_padding = 4,
  right_padding = 4,
  minimal_width = TOT_WIDTH,
  maximal_width = TOT_WIDTH,
  default_graphical_set = rounded_button_graphical_set(0, 0),
  hovered_graphical_set = rounded_button_graphical_set(34, 0, true),
  clicked_graphical_set = rounded_button_graphical_set(51, 0),
  disabled_graphical_set = rounded_button_graphical_set(68, 0),
  --[[
  selected_graphical_set = rounded_button_graphical_set(68, 0),
  selected_hovered_graphical_set = rounded_button_graphical_set(68, 0),
  selected_clicked_graphical_set = rounded_button_graphical_set(68, 0),
  --]]
}

default_gui["tral_label_id"] = {
  type = "label_style",
  parent = "tooltip_heading_label",
  horizontal_align = "right",
  minimal_width = WIDTH[1],
  maximal_width = WIDTH[1],
}
default_gui["tral_label_state"] = {
  type = "label_style",
  parent = "tooltip_heading_label",
  horizontal_align = "left",
  minimal_width = WIDTH[2],
  maximal_width = WIDTH[2],
}
default_gui["tral_label_time"] = {
  type = "label_style",
  parent = "tooltip_heading_label",
  horizontal_align = "right",
  minimal_width = WIDTH[3],
  maximal_width = WIDTH[3],
}

data:extend({{
	type = "custom-input",
	name = "tral-toggle-hotkey",
	key_sequence = "SHIFT + T",
	consuming = "none",
}})
