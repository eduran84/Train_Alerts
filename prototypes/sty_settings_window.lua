local width = defs.constants.textbox_width * 5 + defs.constants.id_label_width + 2*36 + 48
default[style_names.helper_label] = {
  type = "label_style",
  minimal_width = width,
  maximal_width = width,
  single_line = false,
}

default[style_names.table_header_frame] = {
  type = "frame_style",
  horizontally_stretchable = "on",
  padding = 0,
  direction = "horizontal",
  horizontal_flow_style = {
    type = "horizontal_flow_style",
    vertical_align = "center"
  },
  vertical_align = "center",
}
default[style_names.table_body_frame] = {
  type = "frame_style",
  horizontally_stretchable = "on",
  padding = 0,
}

default[style_names.table_row_flow] = {
  type = "horizontal_flow_style",
  vertical_align = "center"
}

default[style_names.image_flow] = {
  type = "horizontal_flow_style",
  horizontal_align = "center",
  minimal_width = defs.constants.textbox_width,
  maximal_width = defs.constants.textbox_width
}

default[style_names.id_label] = {
  type = "label_style",
  parent = "hoverable_bold_label",
  horizontal_align = "right",
  minimal_width = defs.constants.id_label_width,
  maximal_width = defs.constants.id_label_width,
}

default[style_names.textbox_valid] = {
  type = "textbox_style",
  width = defs.constants.textbox_width,

}
default[style_names.textbox_invalid] = {
  type = "textbox_style",
  parent = style_names.textbox_valid,
  font_color = {},
  default_background = {
    base = {
      filename = defs.pathes.sprites.gui_spritesheet,
      position = {17, 34},
      corner_size = 8
    },
    shadow = textbox_dirt
  },
  disabled_font_color = util.premul_color{1, 1, 1, 0.5},
  active_background = {
    base = {
      filename = defs.pathes.sprites.gui_spritesheet,
      position = {0, 34},
      corner_size = 8,
    },
    shadow = textbox_dirt,
  },
  disabled_background = {
    base = {
      filename = defs.pathes.sprites.gui_spritesheet,
      position = {34, 34},
      corner_size = 8,
    },
    shadow = textbox_dirt,
  },
  selection_background_color= {218, 76, 76},
}