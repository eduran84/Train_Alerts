--[[ Copyright (c) 2019 Eduran
 * Part of Train Alerts GUI
 *
 * See LICENSE.md in the project directory for license information.
--]]
local names = defs.names.gui.table
local col_width = defs.constants.table_col_width

default[names.outer_flow] = {
  type = "vertical_flow_style",
  parent = "vertical_flow",
  vertical_spacing = 0,
}

default[names.header_frame] = {
  type = "frame_style",
  horizontally_stretchable = "on",
  left_padding = 4,
  direction = "horizontal",
  vertical_align = "center",
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
}

local col_width_def = {}
local col_align_def = {}
for i = 1,6 do
  col_width_def[i] = {column = i, width = col_width[i]}
  col_align_def[i] = {column = i, alignment = "middle-center"}
end
col_align_def[1] = {column = 1, alignment = "middle-right"}


default[names.table] = {
  type = "table_style",
  horizontal_spacing = 2,
  vertical_spacing = 2,
  column_widths = col_width_def,
  column_alignments = col_align_def,
  --[[
  column_graphical_set = {
    filename = "__core__/graphics/gui.png",
    corner_size = 3,
    position = {8, 0},
    scale = 1
  }
  --]]
}