-- load modules
local mod_gui = require("mod-gui")
local EGM_Frame = require(defs.pathes.modules.EGM_Frame)
local EGM_Table = require(defs.pathes.modules.EGM_Table)
--localize functions and variables
local pairs, log2 = pairs, log2
local register_ui, unregister_ui = util.register_ui, util.unregister_ui
local names = defs.names
local element_names = names.gui.elements

local tsm
local data = {
  viewing_players = {},
  frames = {},
  tables = {},
}

local function build_frame(pind)
  if debug_log then
    log2("Creating settings window for player", game.players[pind].name)
  end
  local frame = EGM_Frame.build(
    game.players[pind].gui.center,
    {
      name = element_names.setting_frame,
      caption = {"tral.setting-frame-caption"},
      direction = "vertical",
    }
  )
  register_ui(
    data.ui_elements,
    EGM_Frame.add_button(frame, {
      type = "sprite-button",
      style = "tral_title_button",
      sprite = "utility/close_white",
    }),
    {name = "close_window"}
  )
  frame.visible = false

  local headers = {[1] = {type = "label", style = "caption_label", caption = {"tral.settings-col-header-1"}}}
  local spritelist = {
    [2] = "item/rail-signal",
    [3] = "item/train-stop",
    [4] = "utility/questionmark",
    [5] = "utility/show_player_names_in_map_view",
    [6] = "utility/questionmark",
  }
  for i = 2, 6 do
    headers[i] = {
      type = "sprite",
      sprite = spritelist[i],
      tooltip = {"tral.settings-col-header-tt-"..i}
    }
  end
  local table = EGM_Table.build(
    EGM_Frame.get_flow(frame),
    {
      column_count = 6,
      header_elements = headers,
    }
  )
  return frame, table
end

local function reset(pind)
  local frame = data.frames[pind]
  if frame and frame.valid then frame:destroy() end
  data.frames[pind], data.tables[pind] = build_frame(pind)
end

local function get_frame(pind)
  local frame = data.frames[pind]
  if frame and frame.valid then return frame end
  reset(pind)
  return data.frames[pind]
end

local function get_table(pind)
  local table = data.tables[pind]
  if table and table.valid then return table end
  reset(pind)
  return data.tables[pind]
end

local function open(pind)
  local frame = get_frame(pind)
  frame.visible = true
  game.players[pind].opened = frame
end

local add_train_to_list
do
  local cell_def = {[1] = {type = "label", style = "hoverable_bold_label", name = "tral_trainlabel_"}}
  for i = 2, 6 do
    cell_def[i] = {type = "text-box", style = "short_number_textfield", name = "0"}
  end
  local i2state = {
    defines.train_state.wait_signal,
    defines.train_state.wait_station,
    defines.train_state.no_path,
    defines.train_state.manual_control,
    defines.train_state.no_schedule,
  }
  --local monitor_states = shared.train_state_monitor.monitor_states
  add_train_to_list =  function(event)
    local train_id = event.train_id
    if train_id and not(tsm.ignored_trains[train_id]) then
      local action_def = {[1] = {name = "train_label_clicked", train_id = train_id}}
      cell_def[1].caption = train_id
      cell_def[1].name = "tral_trainlabel_" .. train_id
      tsm.ignored_trains[train_id] = {
        train = tsm.monitored_trains[train_id].train,
        ["ok_states"] = {
          [defines.train_state.wait_signal] = true,
          [defines.train_state.wait_station] = true,
        },
        monitor_states = {},
      }
      local monitor_states = shared.train_state_monitor.monitor_states
      for i = 2, 6 do
        local timeout = monitor_states[i2state[i]]
        cell_def[i].text = timeout and (timeout - 2) / 60 or -1
        cell_def[i].name = train_id .. "_" .. i
        action_def[i] = {name = "text_changed", train_id = train_id, column = i}
      end
      for pind in pairs(game.players) do
        local tbl_add = get_table(pind).add
        for i, cell in pairs(cell_def) do
          register_ui(data.ui_elements, tbl_add(cell), action_def[i])
        end
      end
    end
    open(event.player_index)
  end
end

local function remove_train_from_list(event, train_id)
  tsm.ignored_trains[train_id] = nil
  for pind in pairs(game.players) do
    local tbl = get_table(pind)
    local elem = tbl["tral_trainlabel_" .. train_id]
    unregister_ui(data.ui_elements, elem)
    elem.destroy()
    for i = 2, 6 do
      elem = tbl[train_id .. "_" .. i]
      unregister_ui(data.ui_elements, elem)
      elem.destroy()
    end
  end
end


local gui_actions = {
  close_window = function(event, action)
    get_frame(event.player_index).visible = false
  end,
  train_label_clicked = function(event, action)
    local train_id = action.train_id
    if event.button == 2 and tsm.ignored_trains[train_id] then --LMB
      util.train.open_train_gui(event.player_index, tsm.ignored_trains[train_id].train)
      local frame = get_frame(event.player_index)
      frame.visible = true
    else
      remove_train_from_list(event, train_id)
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

local function on_gui_closed(event)
  log2("on_gui_closed", event)
  if event.element and event.element.name == element_names.setting_frame then
    get_frame(event.player_index).visible = false
  elseif event.entity and event.entity.type == "locomotive" then
    local frame = get_frame(event.player_index)
    if frame.visible then
      game.players[event.player_index].opened = frame
    end
  end
end

local events =
{
  [defines.events.on_gui_click] = on_gui_input,
  [defines.events.on_player_created] = nil,
  [defines.events.on_gui_closed] = on_gui_closed
}

local private_events =
{
  [defs.events.on_train_ignored] = add_train_to_list
}

-- public module API
local gui_settings_window = {}

function gui_settings_window.on_init()
  global.gui_settings_window = global.gui_settings_window or data
  tsm = global.train_state_monitor
  for pind in pairs(game.players) do
    on_player_created({player_index = pind})
  end
end

function gui_settings_window.on_load()
  data = global.gui_settings_window
  tsm = global.train_state_monitor
end

function gui_settings_window.get_events()
  return events
end

function gui_settings_window.get_private_events()
  return private_events
end

function gui_settings_window.on_configuration_changed(data)
end

return gui_settings_window