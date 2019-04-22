default[style_names.table_header_frame] = {
  type = "frame_style",
  horizontally_stretchable = "on",
  left_padding = 4,
  direction = "horizontal",
  vertical_align = "center",
}
default[style_names.table_body_frame] = {
  type = "frame_style",
  padding = 0,
}

default[style_names.table_pane] = {
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

default[style_names.table_row_flow] = {
  type = "horizontal_flow_style",
  vertical_align = "center"
}

default[style_names.table_row_flow] = {
  type = "horizontal_flow_style",
  vertical_align = "center"
}

default[style_names.id_label] = {
  type = "label_style",
  parent = "hoverable_bold_label",
  horizontal_align = "right",
  minimal_width = defs.constants.id_label_width,
  maximal_width = defs.constants.id_label_width,
}