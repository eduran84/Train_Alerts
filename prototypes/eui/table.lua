local names = require("script.defines").names.gui.table

default[names.outer_flow] = {
  type = "vertical_flow_style",
  parent = "vertical_flow",
  vertical_spacing = 0,
}

default[names.header_frame] = {
  type = "frame_style",
  horizontally_stretchable = "on",
  left_padding = 4,
}
default[names.body_frame] = {
  type = "frame_style",
  padding = 0,
}

default[names.pane] = {
  type = "scroll_pane_style",
  vertically_squashable = "on",
  horizontally_squashable = "on",
  vertical_flow_style = { type = "vertical_flow_style" },
  horizontal_scrollbar_style = { type = "horizontal_scrollbar_style" },
  vertical_scrollbar_style = { type = "vertical_scrollbar_style" },
  graphical_set = {},
  top_padding  = 4,
  right_padding = 4,
  bottom_padding = 4,
  left_padding = 4,
  extra_padding_when_activated = 0,
  vertical_scroll_policy = "auto-and-reserve-space",
}

default[names.table] = {
  type = "table_style",
  horizontal_spacing = 2,
  vertical_spacing = 2,
  --[[
  column_widths = {
    {column = 1, width = 20},
    {column = 2, width = 310},
    {column = 3, width = 100},
  },
  --]]
  column_graphical_set = {
    filename = "__core__/graphics/gui.png",
    corner_size = 3,
    position = {8, 0},
    scale = 1
  }
}