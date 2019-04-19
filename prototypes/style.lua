--[[ Copyright (c) 2019 Eduran
 * Part of Train Alerts GUI
 *
 * See LICENSE.md in the project directory for license information.
--]]

default = data.raw["gui-style"].default
defs = require("script.defines")
require("prototypes.sprites")

-- alert button styles
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

default["tral_button_row"] = {
  type = "button_style",
  horizontal_align = "left",
  left_padding = 4,
  right_padding = 4,
  minimal_width = defs.constants.button_outer_width,
  maximal_width = defs.constants.button_outer_width,
  default_graphical_set = rounded_button_graphical_set(0, 0),
  hovered_graphical_set = rounded_button_graphical_set(34, 0, true),
  clicked_graphical_set = rounded_button_graphical_set(51, 0),
  disabled_graphical_set = rounded_button_graphical_set(68, 0),
}
default["tral_label_id"] = {
  type = "label_style",
  parent = "tooltip_heading_label",
  horizontal_align = "right",
  minimal_width = defs.constants.button_inner_width[1],
  maximal_width = defs.constants.button_inner_width[1],
}
default["tral_label_state"] = {
  type = "label_style",
  parent = "tooltip_heading_label",
  horizontal_align = "left",
  minimal_width = defs.constants.button_inner_width[2],
  maximal_width = defs.constants.button_inner_width[2],
}
default["tral_label_time"] = {
  type = "label_style",
  parent = "tooltip_heading_label",
  horizontal_align = "right",
  minimal_width = defs.constants.button_inner_width[3],
  maximal_width = defs.constants.button_inner_width[3],
}


default["tral_title_button"] = {
  type = "button_style",
  parent = "close_button",
  size = 24,
}


require("prototypes.eui.shared")
require("prototypes.eui.frame")
require("prototypes.eui.table")