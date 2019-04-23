default = data.raw["gui-style"].default
style_names = defs.names.styles

require("prototypes.sprites")

-- shared styles --

default[style_names.title_button] = {
  type = "button_style",
  parent = "close_button",
  size = 24,
}
default[style_names.vertical_spacer_flow] = {
  type = "horizontal_flow_style",
  vertically_stretchable = "on",
  paddding = 0,
}
default[style_names.horizontal_spacer_flow] = {
  type = "horizontal_flow_style",
  horizontally_stretchable = "on",
  paddding = 0,
}
default[style_names.title_flow] = {
  type = "horizontal_flow_style",
  parent = "horizontal_flow",
  top_padding  = -2,
  right_padding = 0,
  bottom_padding = 6,
  left_padding = 0,
}

default[style_names.title] = {
  type = "label_style",
  font = "heading-1",
  font_color = heading_font_color,
}

default[style_names.table_pane] = {
  type = "scroll_pane_style",
  vertical_flow_style = {
    type = "vertical_flow_style",
    padding = 0,
  },
  graphical_set = {},
  top_padding  = 4,
  right_padding = 0,
  bottom_padding = 4,
  left_padding = 0,
  extra_padding_when_activated = 0,
}

require("prototypes.sty_alert_window")
require("prototypes.sty_settings_window")