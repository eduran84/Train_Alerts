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

local sprite_path =  "__Train_Alerts__/graphics/shortcut/"
defs.spritepath = {
  ["shortcut_x32"] = sprite_path .. "x32.png",
  ["shortcut_x32_bw"] = sprite_path .. "x32_bw.png",
  ["shortcut_x24"] = sprite_path .. "x24.png",
  ["shortcut_x24_bw"] = sprite_path .. "x24_bw.png",
}

defs.constants.trains_per_tick = 15

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