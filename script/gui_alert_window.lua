--[[ Copyright (c) 2019 Eduran
 * Part of Train Alerts GUI
 *
 * See LICENSE.md in the project directory for license information.
--]]

-- load modules
local mod_gui = require("mod-gui")
local EUI_Frame = require("script.eui.EUI_Frame")

--localize functions and variables
local pairs, log2 = pairs, log2
local gui
local names = defs.names
local element_names = names.gui.elements
local toggle_shortcut_name = names.controls.toggle_shortcut
local WIDTH = defs.constants.button_inner_width

-- private UI functions
local function get_frame(pind)
  local frame_flow = mod_gui.get_frame_flow(game.players[pind])
  local frame_obj = gui[element_names.main_frame][pind]
  if frame_obj and frame_obj:is_valid() then
    return frame_obj
  else
    if debug_log then log2("Creating GUI for player", game.players[pind].name) end
    if frame_obj then frame_obj:destroy() end
    frame_obj = EUI_Frame.build{
      parent = frame_flow,
      caption = {"tral.frame-caption"},
      direction = "vertical",
      style = "tral_transparent_frame",
    }
    frame_obj:style().maximal_height = settings.get_player_settings(game.players[pind])["tral-window-height"].value
    frame_obj:add_title_button({
      type = "sprite-button",
      style = "tral_title_button",
      tooltip = {"tral.help-button-tt"},
      sprite = names.gui.sprites.questionmark_white,
      name = element_names.help_button,
    })
    frame_obj:add_title_button({
      type = "sprite-button",
      style = "tral_title_button",
      tooltip = {"tral.ignore-button-tt"},
      sprite = names.gui.sprites.ignore_white,
      name = element_names.ignore_button,
    })

    local tbl = frame_obj:add{type = "table", column_count = 3}
    for i = 1, 3 do
      local label = tbl.add{
        type = "label",
        style = "caption_label",
        caption = {"tral.col-header-"..i}
      }
      label.style.width = WIDTH[i]
    end
    frame_obj:add{
      type = "scroll-pane",
      vertical_scroll_policy = "auto",
      horizontal_scroll_policy = "never",
      name = element_names.main_pane
    }.add{type = "table", name = element_names.main_table, column_count = 1}
    frame_obj:hide()
    gui[element_names.main_frame][pind] = frame_obj
    return frame_obj
  end
end

local function get_table(pind)
  local frame_obj = get_frame(pind)
  return frame_obj.container[element_names.main_pane]
      and frame_obj.container[element_names.main_pane][element_names.main_table]
end

local function show(pind)
  get_frame(pind):show()
  game.players[pind].set_shortcut_toggled(
    toggle_shortcut_name,
    true
  )
end

local function hide(pind)
  get_frame(pind):hide()
  game.players[pind].set_shortcut_toggled(toggle_shortcut_name, false)
end

-- for debugging, to simulate UI elements becoming invalid
commands.add_command("reset", "",
  function(event)
    game.players[event.player_index].gui.left.clear()
    gui[element_names.main_frame] = {}
  end
)

-- public functions
local function player_init(pind)
  gui.show_on_alert[pind] = settings.get_player_settings(game.players[pind])["tral-open-on-alert"].value or nil
end

local function init()
  gui = global.gui
  global.gui[element_names.main_frame] = {}
  global.gui.show_on_alert = {}
  global.gui.active_alert_count = 0
  for pind, player in pairs(game.players) do
    player_init(pind)
  end
end

local function on_load()
  gui = global.gui
  for pind, frame_obj in pairs(gui[element_names.main_frame]) do
    EUI_Frame.restore_mt(frame_obj)
  end
end

local add_row
do
  local tostring = tostring
  local button_definition = {
    type = "button",
    style = "tral_button_row",
    name = "tral_trainbt_",
    tooltip = {"tral.button-tooltip"},
  }
  local label_definitions = {
    [1] = {type = "label", style = "tral_label_id"},
    [2] = {type = "label", style = "tral_label_state"},
    [3] = {type = "label", style = "tral_label_time"}
  }
  local flow_definition = {type = "flow", ignored_by_interaction = true}

  add_row = function(train_id, state, time)
    button_definition.name = "tral_trainbt_" .. train_id
    label_definitions[1].caption = tostring(train_id)
    label_definitions[2].caption = state
    label_definitions[3].caption = time
    gui.active_alert_count = gui.active_alert_count + 1
    for pind in pairs(game.players) do
      local button = get_table(pind).add(button_definition).add(flow_definition)
      for i = 1, 3 do
        button.add(label_definitions[i])
      end
      if gui.show_on_alert[pind] then show(pind) end
    end
  end
end

local function delete_row(train_id)
  gui.active_alert_count = gui.active_alert_count - 1
  for pind in pairs(game.players) do
    local button = get_table(pind)["tral_trainbt_" .. train_id]
    if button and button.valid then
      button.destroy()
    end
    if gui.active_alert_count == 0 and gui.show_on_alert[pind] then
      hide(pind)
    end
  end
end

local function update_time(train_id, new_time)
  for pind in pairs(game.players) do
    local button = get_table(pind)["tral_trainbt_" .. train_id]
    button.children[1].children[3].caption = new_time
  end
end

local function update_state(train_id, new_state)
  for pind in pairs(game.players) do
    local button = get_table(pind)["tral_trainbt_" .. train_id]
    button.children[1].children[2].caption = new_state
  end
end

script.on_event(names.controls.toggle_hotkey,
  function(event)
    if debug_log then log2("Toggle hotkey pressed. Event data:", event) end
    game.players[event.player_index].set_shortcut_toggled(
      toggle_shortcut_name,
      get_frame(event.player_index):toggle()
    )
  end
)

script.on_event(
  defines.events.on_lua_shortcut,
  function(event)
    if debug_log then log2("Toggle shortcut pressed. Event data:", event) end
    if event.prototype_name == defs.names.controls.toggle_shortcut then
      game.players[event.player_index].set_shortcut_toggled(
        toggle_shortcut_name,
        get_frame(event.player_index):toggle()
      )
    end
  end
)

return {
  init = init,
  on_load = on_load,
  player_init = player_init,
  add_row = add_row,
  delete_row = delete_row,
  update_time = update_time,
  update_state = update_state,
}
