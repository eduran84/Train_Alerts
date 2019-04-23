-- alert button styles

default[style_names.alert_window_frame] = {
  type = "frame_style",
  use_header_filler = false,
  left_padding = 4,
  right_padding = 4,
  graphical_set = {
    base = {
      filename = defs.pathes.sprites.gui_spritesheet,
      position = {0, 17},
      corner_size = 8
    },
    shadow = default_dirt,
  }
}

local function rounded_button_glow(tint_value)
  return
  {
    filename = defs.pathes.sprites.gui_spritesheet,
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
      filename = defs.pathes.sprites.gui_spritesheet,
      position = {x, y},
      corner_size = size
    },
    shadow = rounded_button_glow(default_dirt_color),
    glow = glow,
  }

end

default[style_names.row_button] = {
  type = "button_style",
  horizontal_align = "left",
  left_padding = 0,
  right_padding = 0,
  minimal_width = defs.constants.button_outer_width,
  maximal_width = defs.constants.button_outer_width,
  default_graphical_set = rounded_button_graphical_set(0, 0),
  hovered_graphical_set = rounded_button_graphical_set(34, 0, true),
  clicked_graphical_set = rounded_button_graphical_set(51, 0),
  disabled_graphical_set = rounded_button_graphical_set(68, 0),
}
default[style_names.button_label_id] = {
  type = "label_style",
  parent = "tooltip_heading_label",
  horizontal_align = "right",
  minimal_width = defs.constants.button_inner_width[1],
  maximal_width = defs.constants.button_inner_width[1],
}
default[style_names.button_label_state] = {
  type = "label_style",
  parent = "tooltip_heading_label",
  horizontal_align = "left",
  minimal_width = defs.constants.button_inner_width[2],
  maximal_width = defs.constants.button_inner_width[2],
}
default[style_names.button_label_time] = {
  type = "label_style",
  parent = "tooltip_heading_label",
  horizontal_align = "right",
  minimal_width = defs.constants.button_inner_width[3],
  maximal_width = defs.constants.button_inner_width[3],
}