-- load modules
local mod_gui = require("mod-gui")
local EGM_Frame = require("script.EGM.frame")

--localize functions and variables
local pairs, log2 = pairs, log2
local names = defs.names
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
}

-- private UI functions
local function build_frame(pind)
  local player = game.players[pind]
  if debug_mode then log2("Creating Alert window for player", player.name) end
  local frame = EGM_Frame.build(
    mod_gui.get_frame_flow(player),
    {
      caption = {"tral.frame-caption"},
      direction = "vertical",
      style = "tral_transparent_frame",
    }
  )
  frame.style.maximal_height = settings.get_player_settings(player)[names.settings.window_height].value
  EGM_Frame.add_button(frame, {
    type = "sprite-button",
    style = "tral_title_button",
    tooltip = {"tral.help-button-tt"},
    sprite = names.gui.sprites.questionmark_white,
    name = element_names.help_button,
  })
  EGM_Frame.add_button(frame, {
    type = "sprite-button",
    style = "tral_title_button",
    tooltip = {"tral.ignore-button-tt"},
    sprite = names.gui.sprites.ignore_white,
    name = element_names.ignore_button,
  })
  data.alert_frames[pind] = frame
  frame.visible = false

  local tbl = EGM_Frame.add_element(frame, {type = "table", column_count = 3})
  for i = 1, 3 do
    local label = tbl.add{
      type = "label",
      style = "caption_label",
      caption = {"tral.col-header-"..i}
    }
    label.style.width = WIDTH[i]
  end

  data.alert_tables[pind] = (EGM_Frame.add_element(frame, {
    type = "scroll-pane",
    vertical_scroll_policy = "auto",
    horizontal_scroll_policy = "never",
  }).add{type = "table", column_count = 1})
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
    style = "tral_button_row",
    name = element_names.train_button,
    tooltip = {"tral.button-tooltip"},
  }
  local label_definitions = {
    [1] = {type = "label", style = "tral_label_id"},
    [2] = {type = "label", style = "tral_label_state"},
    [3] = {type = "label", style = "tral_label_time"}
  }
  local flow_definition = {type = "flow", ignored_by_interaction = true}

  add_row = function(event)
    local train_id = event.train_id
    button_definition.name = element_names.train_button .. train_id
    label_definitions[1].caption = tostring(train_id)
    label_definitions[2].caption = event.state
    label_definitions[3].caption = event.time
    data.active_alert_count = data.active_alert_count + 1
    for pind in pairs(game.players) do
      local button = get_table(pind).add(button_definition).add(flow_definition)
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
      button.destroy()
    end
    if data.active_alert_count == 0 and data.show_on_alert[pind] then
      hide(pind)
    end
  end
end

local function update_button(event)
  for pind in pairs(data.viewing_players) do
    local button = get_table(pind)[element_names.train_button .. event.train_id].children[1]
    if event.name == "time" then
      button.children[3].caption = event.new_value
    else
      button.children[2].caption = event.new_value
    end
  end
end

 local handler = {
  [defs.names.gui.elements.ignore_button] = nil,--ui_settings.open,
  [defs.names.gui.elements.help_button] = nil,
  [defs.names.gui.elements.close_button] = nil,-- ui_settings.close,
}
local open_train_gui = require("__OpteraLib__.script.train").open_train_gui
local match, tonumber = string.match, tonumber
local raise_internal_event = raise_internal_event
local function on_gui_input(event)
  if event.element and event.element.name then
    local name = event.element.name
    if debug_mode then log2("on_gui_click event received:", event) end

    if handler[name] then
      handler[name](event)
    else
      -- train buttons
      local train_id = tonumber(match(name, element_names.train_button .."(%d+)"))
      if train_id then
        if event.button == 2 and tsm.monitored_trains[train_id] then
          if false then --event.shift then
            -- Shift + LMB -> add train to ignore list
            ui_settings.add_train_to_list(
              event,
              train_id,
              tsm.monitored_trains[train_id].train,
              monitor_states
            )
            force_state_check(tsm.monitored_trains[train_id].train)
          else
            -- LMB -> open train UI
            open_train_gui(event.player_index, tsm.monitored_trains[train_id].train)
          end
        else
          -- RMB -> remove train from list
          raise_internal_event(defs.events.on_alert_removed, train_id)
        end
      end
    end
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
end

local events =
{
  [defines.events.on_gui_click] = on_gui_input,
  [names.controls.toggle_hotkey] = on_toggle_hotkey,
  [defines.events.on_lua_shortcut] = on_toggle_shortcut,
  [defines.events.on_player_created] = on_player_created,
}

local internal_events =
{
  [defs.events.on_new_alert] = add_row,
  [defs.events.on_state_updated] = update_button,
  [defs.events.on_alert_expired] = delete_row,
}
-- public module API
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

function gui_alert_window.get_internal_events()
  return internal_events
end

function gui_alert_window.on_configuration_changed(data)
end

return gui_alert_window
