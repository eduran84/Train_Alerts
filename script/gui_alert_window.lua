-- load modules
local mod_gui = require("mod-gui")
local EUI_Frame = require("script.eui.EUI_Frame")

--localize functions and variables
local pairs, log2 = pairs, log2
local names = defs.names
local element_names = names.gui.elements
local toggle_shortcut_name = names.controls.toggle_shortcut
local WIDTH = defs.constants.button_inner_width

local tsm
local data = {
  [element_names.main_frame] = {},
  show_on_alert = {},
  active_alert_count = 0,
}

-- private UI functions
local function get_frame(pind)
  local frame_flow = mod_gui.get_frame_flow(game.players[pind])
  local frame_obj = data[element_names.main_frame][pind]
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
    data[element_names.main_frame][pind] = frame_obj
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

local add_row
do
  local tostring = tostring
  local button_definition = {
    type = "button",
    style = "tral_button_row",
    name = "tral_trainbt_a",
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
    button_definition.name = "tral_trainbt_a" .. train_id
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
    local button = get_table(pind)["tral_trainbt_a" .. train_id]
    if button and button.valid then
      button.destroy()
    end
    if data.active_alert_count == 0 and data.show_on_alert[pind] then
      hide(pind)
    end
  end
end

local function update_time(train_id, new_time)
  for pind in pairs(game.players) do
    local button = get_table(pind)["tral_trainbt_a" .. train_id]
    button.children[1].children[3].caption = new_time
  end
end

local function update_state(train_id, new_state)
  for pind in pairs(game.players) do
    local button = get_table(pind)["tral_trainbt_a" .. train_id]
    button.children[1].children[2].caption = new_state
  end
end

 local handler = {
  [defs.names.gui.elements.ignore_button] = nil,--ui_settings.open,
  [defs.names.gui.elements.help_button] = nil,
  [defs.names.gui.elements.close_button] = nil,-- ui_settings.close,
}
local open_train_gui = require("__OpteraLib__.script.train").open_train_gui
local match, tonumber = string.match, tonumber
local function on_gui_input(event)
  if event.element and event.element.name then
    if debug_log then log2("on_gui_click event received:", event) end
    if handler[event.element.name] then
      handler[event.element.name](event)
    else
      -- train buttons
      local type, train_id = match(event.element.name, "tral_trainbt_([ai])(%d+)")
      train_id = tonumber(train_id)
      if train_id then
        if type == "a" then  -- click on train in alert list
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
            --stop_monitoring(train_id)
          end
        end
      end
    end
  end
end

local function on_toggle_hotkey(event)
  if debug_log then log2("Toggle hotkey pressed. Event data:", event) end
  game.players[event.player_index].set_shortcut_toggled(
    toggle_shortcut_name,
    get_frame(event.player_index):toggle()
  )
end

local function on_toggle_shortcut(event)
  if debug_log then log2("Toggle shortcut pressed. Event data:", event) end
  if event.prototype_name == toggle_shortcut_name then
    game.players[event.player_index].set_shortcut_toggled(
      toggle_shortcut_name,
      get_frame(event.player_index):toggle()
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
  [defs.events.on_state_updated] = update_state,
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
  for pind, frame_obj in pairs(data[element_names.main_frame]) do
    EUI_Frame.restore_mt(frame_obj)
  end
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
