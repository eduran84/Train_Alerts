--[[ Copyright (c) 2019 Eduran
 * Part of Train Alerts GUI
 *
 * See LICENSE.md in the project directory for license information.
--]]
local names = require("script.defines").names.gui.frame


default["tral_transparent_frame"] = {
  type = "frame_style",
  use_header_filler = false,
  left_padding = 4,
  right_padding = 4,
  graphical_set = {
    base = {filename = "__Train_Alerts__/graphics/gui.png", position = {0, 17}, corner_size = 8},
    shadow = default_dirt,
  }
}

default[names.outer_frame] = {
  type = "frame_style",
  parent = "tral_transparent_frame",
}

default[names.title_flow] = {
  type = "horizontal_flow_style",
  parent = "horizontal_flow",
  top_padding  = -2,
  right_padding = 0,
  bottom_padding = 6,
  left_padding = 0,
}

default[names.title] = {
  type = "label_style",
  font = "heading-1",
  font_color = heading_font_color,
}

