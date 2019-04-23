-- load modules
local mod_gui = require("mod-gui")
local EGM_Frame = require(defs.pathes.modules.EGM_Frame)
--localize functions and variables
local pairs, log2 = pairs, log2
local register_ui, unregister_ui = util.register_ui, util.unregister_ui
local names = defs.names
local styles = names.styles
local element_names = names.gui.elements
local toggle_shortcut_name = names.controls.toggle_shortcut
local WIDTH = defs.constants.button_inner_width

local tsm
local data = {
  viewing_players = {},
  alert_frames = {},
  alert_tables = {},
  show_on_alert = {},
  active_alert_count = 0,
  ui_elements = {},
}

-- UI functions --
local function build_frame(pind)
  local player = game.players[pind]
  if debug_mode then log2("Creating Alert window for player", player.name) end
  local frame = EGM_Frame.build(
    mod_gui.get_frame_flow(player),
    {
      caption = {"tral.frame-caption"},
      direction = "vertical",
      style = styles.alert_window_frame,
    }
  )
  frame.style.maximal_height = settings.get_player_settings(player)[names.settings.window_height].value
  --[[
  register_ui(
    data.ui_elements,
    EGM_Frame.add_button(frame, {
      type = "sprite-button",
      style = "tral_title_button",
      tooltip = {"tral.help-button-tt"},
      sprite = names.sprites.questionmark_white,
    }),
    {name = "show_help"}
  )--]]
  register_ui(
    data.ui_elements,
    EGM_Frame.add_button(frame, {
      type = "sprite-button",
      style = styles.title_button,
      tooltip = {"tral.ignore-button-tt"},
      sprite = "utility/clock",  --names.sprites.ignore_white,
    }),
    {name = "open_settings"}
  )
  data.alert_frames[pind] = frame
  frame.visible = false

  local tbl = EGM_Frame.add_element(frame, {type = "flow"})
  tbl.style.left_padding = 4
  for i = 1, 3 do
    local label = tbl.add{
      type = "label",
      style = "caption_label",
      caption = {"tral.col-header-"..i}
    }
    label.style.width = WIDTH[i]
  end

  data.alert_tables[pind] = (
    EGM_Frame.add_element(frame, {
      type = "scroll-pane",
      style = styles.table_pane,
      vertical_scroll_policy = "auto",
      horizontal_scroll_policy = "never",
    })
  )
  return frame
end

local function get_frame(pind)
  local frame = data.alert_frames[pind]
  if frame and frame.valid then
    return frame
  else
    return build_frame(pind)
  end
end

local function get_table(pind)
  local table = data.alert_tables[pind]
  if table and table.valid then
    return table
  else
    build_frame(pind)
    return data.alert_tables[pind]
  end
end

local function show(pind)
  get_frame(pind).visible = true
  data.viewing_players[pind] = true
  game.players[pind].set_shortcut_toggled(toggle_shortcut_name, true)
end

local function hide(pind)
  get_frame(pind).visible = false
  data.viewing_players[pind] = nil
  game.players[pind].set_shortcut_toggled(toggle_shortcut_name, false)
end

local function toggle(pind)
  local frame = get_frame(pind)
  frame.visible = not frame.visible
  data.viewing_players[pind] = frame.visible or nil
  return frame.visible
end

local add_row
do
  local tostring = tostring
  local button_definition = {
    type = "button",
    style = styles.row_button,
    name = element_names.train_button,
    tooltip = {"tral.button-tooltip"},
  }
  local label_definitions = {
    [1] = {type = "label", style = styles.button_label_id},
    [2] = {type = "label", style = styles.button_label_state},
    [3] = {type = "label", style = styles.button_label_time}
  }
  local flow_definition = {type = "flow", ignored_by_interaction = true}

  add_row = function(event, pind)
    local train_id = event.train_id
    button_definition.name = element_names.train_button .. train_id
    label_definitions[1].caption = tostring(train_id)
    label_definitions[2].caption = event.state
    label_definitions[3].caption = event.time
    data.active_alert_count = data.active_alert_count + 1

    local players = game.players
    if pind then players = {[pind] = true} end
    for pind in pairs(players) do
      local button = get_table(pind).add(button_definition)
      register_ui(
        data.ui_elements,
        button,
        {name = "train_button_clicked", train_id = train_id}
      )
      button = button.add(flow_definition)
      for i = 1, 3 do
        button.add(label_definitions[i])
      end
      if data.show_on_alert[pind] then show(pind) end
    end
  end
end

local function delete_row(train_id)
  data.active_alert_count = data.active_alert_count - 1
  for pind in pairs(game.players) do
    local button = get_table(pind)[element_names.train_button .. train_id]
    if button and button.valid then
      unregister_ui(data.ui_elements, button)
      button.destroy()
    end
    if data.active_alert_count == 0 and data.show_on_alert[pind] then
      hide(pind)
    end
  end
end

local function update_button(event)
  for pind in pairs(data.viewing_players) do
    local button = get_table(pind)[element_names.train_button .. event.train_id]
    if button and button.valid then
      if event.name == "time" then
        button.children[1].children[3].caption = event.time
      else
        button.children[1].children[2].caption = event.state
      end
    else
      add_row(event, pind)
    end
  end
end

local open_train_gui = util.train.open_train_gui
local match, tonumber = string.match, tonumber
local raise_private_event = raise_private_event
local gui_actions = {
  open_settings = function(event, action)
    raise_private_event(defs.events.on_train_ignored, event)
  end,
  train_button_clicked = function(event, action)
    local train_id = action.train_id
    if event.button == 2 and tsm.monitored_trains[train_id] then
      if event.shift then  -- Shift + LMB -> add train to ignore list
        raise_private_event(
          defs.events.on_train_ignored, {
            player_index = event.player_index,
            train_id = train_id,
          }
        )
      else  -- LMB -> open train UI
        open_train_gui(event.player_index, tsm.monitored_trains[train_id].train)
      end
    else  -- RMB -> remove train from list
      raise_private_event(defs.events.on_alert_removed, train_id)
    end
  end,
}

local on_gui_input = function(event)
  local element = event.element
  if not (element and element.valid) then return end
  local player_data = data.ui_elements[event.player_index]
  if not player_data then return end
  local action = player_data[element.index]
  if action then
    if debug_mode then log2("event:", event, "\nplayer data:", player_data) end
    gui_actions[action.name](event, action)
    return true
  end
end

local function on_toggle_hotkey(event)
  if debug_mode then log2("Toggle hotkey pressed. Event data:", event) end
  game.players[event.player_index].set_shortcut_toggled(
    toggle_shortcut_name,
    toggle(event.player_index)
  )
end

local function on_toggle_shortcut(event)
  if debug_mode then log2("Toggle shortcut pressed. Event data:", event) end
  if event.prototype_name == toggle_shortcut_name then
    game.players[event.player_index].set_shortcut_toggled(
      toggle_shortcut_name,
      toggle(event.player_index)
    )
  end
end

local function on_player_created(event)
  local pind = event.player_index
  data.show_on_alert[pind] = settings.get_player_settings(game.players[pind])[names.settings.open_on_alert].value or nil
  build_frame(pind)
end

local function resize_window(event)
  local pind = event.player_index
  get_frame(pind).style.maximal_height = settings.get_player_settings(game.players[pind])[names.settings.window_height].value
end

local setting_actions = {
  [defs.names.settings.open_on_alert] = on_player_created,
  [defs.names.settings.window_height] = resize_window,
}

local function on_settings_changed(event)
  if event.setting and string.match(event.setting, names.mod_prefix) then
    if setting_actions[event.setting] then
      setting_actions[event.setting](event)
      log2("Mod settings changed by player", game.players[event.player_index].name, ".\nSetting changed event:", event)
    end
  end
end

-- public module API --

local events =
{
  [defines.events.on_gui_click] = on_gui_input,
  [names.controls.toggle_hotkey] = on_toggle_hotkey,
  [defines.events.on_lua_shortcut] = on_toggle_shortcut,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_runtime_mod_setting_changed] = on_settings_changed,
}
local private_events =
{
  [defs.events.on_new_alert] = add_row,
  [defs.events.on_state_updated] = update_button,
  [defs.events.on_alert_expired] = delete_row,
}

local gui_alert_window = {}

function gui_alert_window.on_init()
  global.gui_alert_window = global.gui_alert_window or data
  tsm = global.train_state_monitor
  for pind in pairs(game.players) do
    on_player_created({player_index = pind})
  end
end

function gui_alert_window.on_load()
  data = global.gui_alert_window
  tsm = global.train_state_monitor
end

function gui_alert_window.get_events()
  return events
end

function gui_alert_window.get_private_events()
  return private_events
end

function gui_alert_window.on_configuration_changed(data)
end

return gui_alert_window
