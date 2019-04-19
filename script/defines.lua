--[[ Copyright (c) 2019 Eduran
 * Part of Train Alerts GUI
 *
 * See LICENSE.md in the project directory for license information.
--]]
local defs = {
  names = {
    controls = {},
    gui = {}
  },
  dicts = {},
  constants = {},
  spritepath = {},
}

-- EUI names
defs.names.gui.shared = {
  vertical_spacer = "eui-shr/vertical-spacer",
  horizontal_spacer = "eui-shr/horizontal-spacer",
}
defs.names.gui.frame = {
  outer_frame = "eui-frm/outer_frame",
  title_flow = "eui-frm/header_flow",
  title = "eui-frm/title",
}
defs.names.gui.main_frame = "tral-frame"


defs.names.controls = {
  toggle_hotkey = "tral-toggle-hotkey",
  left_mouse = 2,
  right_mouse = 4,
  toggle_shortcut = "tral-toggle-shortcut",
}

defs.names.gui.sprites = {
  questionmark_white = "tral_icon_questionmark_white",
  ignore_white = "tral_icon_ignore_white",
}

defs.names.gui.elements = {
  main_frame = "tral-frame",
  main_table = "tral_table",
  main_pane = "tral-scroll",
  ignore_button = "tral-ignore-button",
  help_button = "tral-help-button",
}

local sprite_path_sc =  "__Train_Alerts__/graphics/shortcut/"
local sprite_path_icon = "__Train_Alerts__/graphics/icons/"
defs.spritepath = {
  shortcut_x32 = sprite_path_sc .. "x32.png",
  shortcut_x32_bw = sprite_path_sc .. "x32_bw.png",
  shortcut_x24 = sprite_path_sc .. "x24.png",
  shortcut_x24_bw = sprite_path_sc .. "x24_bw.png",
  questionmark_white = sprite_path_icon .. "questionmark_white.png",
  ignore_white = sprite_path_icon .. "ignore_white.png",
}

defs.constants.trains_per_tick = 15
defs.constants.button_inner_width = {50, 200, 50}
defs.constants.button_outer_width = 325

defs.dicts.train_state = {
  [defines.train_state.on_the_path] = {"train-states.on_the_path"},
  [defines.train_state.path_lost] = {"train-states.path_lost"},
  [defines.train_state.no_schedule] = {"train-states.no_schedule"},
  [defines.train_state.no_path] = {"train-states.no_path"},
  [defines.train_state.arrive_signal] = {"train-states.arrive_signal"},
  [defines.train_state.wait_signal] = {"train-states.wait_signal"},
  [defines.train_state.arrive_station] = {"train-states.arrive_station"},
  [defines.train_state.wait_station] = {"train-states.wait_station"},
  [defines.train_state.manual_control_stop] = {"train-states.manual_control_stop"},
  [defines.train_state.manual_control] = {"train-states.manual_control"},
}

return defs