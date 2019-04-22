local defs = {
  names = {
    gui = {}
  },
  dicts = {},
  constants = {},
  pathes = {},
}

local mod_prefix = "tral_"
defs.names.mod_prefix = mod_prefix

-- EGM names
defs.names.gui.shared = {
  vertical_spacer = "eui-shr/vertical-spacer",
  horizontal_spacer = "eui-shr/horizontal-spacer",
}
defs.names.gui.frame = {
  outer_frame = "eui-frm/outer_frame",
  title_flow = "eui-frm/header_flow",
  title = "eui-frm/title",
}

defs.names.styles = {
  title_button = mod_prefix .. "title_button",
  table_header_frame = mod_prefix .. "tbl_header_frame",
  table_body_frame = mod_prefix .. "tbl_body_frame",
  table_pane = mod_prefix .. "tbl_pane",
  table_row_flow = mod_prefix .. "tbl_row_flow",
  image_flow = mod_prefix .. "image_flow",
  id_label = mod_prefix .. "train_id_label",
  textbox_valid = mod_prefix .. "textbox_valid",
  textbox_invalid = mod_prefix .. "textbox_invalid",
}

defs.names.gui.sprites = {
  questionmark_white = "tral_icon_questionmark_white",
  ignore_white = "tral_icon_ignore_white",
}

defs.names.gui.elements = {
  train_button = "tral_train_button_",

  ignore_button = "tral-ignore-button",
  help_button = "tral-help-button",

  setting_frame = "tral-settings-frame",
  close_button = "tral-close-settings-button",
  ignore_table = "tral-ignore-list-table"
}

defs.names.controls = {
  toggle_hotkey = "tral-toggle-hotkey",
  left_mouse = 2,
  right_mouse = 4,
  toggle_shortcut = "tral-toggle-shortcut",
}


local tsm_prefix = mod_prefix .. "tsm_"
defs.names.settings = {
  tsm_prefix = tsm_prefix,
  debug_mode = mod_prefix .. "debug_level",
  open_on_alert = mod_prefix .. "open_on_alert",
  window_height = mod_prefix .. "window_height",
  refresh_interval = tsm_prefix .. "refresh_interval",
  timeout_station = tsm_prefix .. "station",
  timeout_signal = tsm_prefix .. "signal",
  timeout_path = tsm_prefix .. "no_path",
  timeout_schedule = tsm_prefix .. "no_schedule",
  timeout_manual = tsm_prefix .. "manual",
}

defs.events = {
  on_new_alert = 1,
  on_state_updated = 2,
  on_alert_expired = 3,
  on_alert_removed = 10,
  on_timeouts_modified = 11,
  on_train_ignored = 20,
}

local tral_gfx_path = "__Train_Alerts__/graphics/"
local sprite_path_sc =  tral_gfx_path .. "shortcut/"
local sprite_path_icon = tral_gfx_path .. "icons/"
defs.pathes.sprites = {
  gui_spritesheet = tral_gfx_path .. "gui.png",
  shortcut_x32 = sprite_path_sc .. "x32.png",
  shortcut_x32_bw = sprite_path_sc .. "x32_bw.png",
  shortcut_x24 = sprite_path_sc .. "x24.png",
  shortcut_x24_bw = sprite_path_sc .. "x24_bw.png",
  questionmark_white = sprite_path_icon .. "questionmark_white.png",
  ignore_white = sprite_path_icon .. "ignore_white.png",
}
local optera_lib = "__OpteraLib__.script."
defs.pathes.modules = {
  queue = "script.queue",
  EGM_Frame = "script.EGM.frame",
  EGM_Table = "script.EGM.table",
  OL_misc = optera_lib .. "misc",
  OL_train = optera_lib .. "train",
  logger = optera_lib .. "logger"
}


defs.constants.trains_per_tick = 15
defs.constants.timeout_offset = 2
defs.constants.button_inner_width = {50, 200, 50}
defs.constants.button_outer_width = 325
defs.constants.table_col_width = {100, 100, 100, 100, 100, 100}
defs.constants.id_label_width = 100
defs.constants.textbox_width = 80

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