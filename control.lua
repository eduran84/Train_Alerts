--[[ Copyright (c) 2019 Eduran
 * Part of Train Alerts GUI
 *
 * See LICENSE.md in the project directory for license information.
--]]

-- load modules
log2 = require("__OpteraLib__.script.logger").log
print = require("__OpteraLib__.script.logger").print
debug_log = settings.global["tral-debug-level"].value
defs = require("script.defines")
local ui = require("script.gui_alert_window")
local Queue = require("script.queue")

--localize functions and variables
local update_interval = settings.global["tral-refresh-interval"].value
local wait_station_state = defines.train_state.wait_station
local data, monitor_states, ok_states
local pairs = pairs
local train_state_dict = defs.dicts.train_state

-- state change helper function
local function stop_monitoring(train_id)
  if data.active_alerts[train_id] then
    ui.delete_row(train_id)
    data.active_alerts[train_id] = nil
    Queue.remove_value(data.update_queue, train_id)
  end
  Queue.remove_value(data.alert_queue, train_id)
  data.monitored_trains[train_id] = nil
  if debug_log then
    log2("No longer monitoring train", train_id)
  end
end

local function start_monitoring(train_id, new_state, train)
  --- add unmonitored train to monitor list
  if new_state == wait_station_state and
      data.ltn_stops and
      monitor_states[wait_station_state] then
    -- dont trigger alert fors trains stopped at LTN depots
    local stop_id = train.station and train.station.unit_number
    if stop_id and data.ltn_stops[stop_id] and
        data.ltn_stops[stop_id].isDepot then
      return
    end
  end -- if new_state == train_state.wait_station ...
  local alert_time = game.tick + monitor_states[new_state]
  alert_time = Queue.insert(data.alert_queue, alert_time, train_id)
  data.monitored_trains[train_id] = {
    state = new_state,
    start_time = game.tick,
    alert_time = alert_time,
    train = train
  }
  if debug_log then
    log2("Monitoring train", train_id, "=", data.monitored_trains[train_id])
  end
end

local function update_monitoring(train_id, new_state)
  data.monitored_trains[train_id].state = new_state
  if data.active_alerts[train_id] then
    ui.update_state(train_id, train_state_dict[new_state])
  else
    Queue.remove_value(data.alert_queue, train_id)
    local alert_time = game.tick + monitor_states[new_state]
    data.monitored_trains[train_id].start_time = game.tick
    data.monitored_trains[train_id].alert_time = Queue.insert(data.alert_queue, alert_time, train_id)
  end
  if debug_log then
    log2("Updated train", train_id, "=", data.monitored_trains[train_id])
  end
end

--[[ on_state_change
* triggered on_train_changed_state
* adds trains with potential alert states to data.monitored_trains
* removes trains from data.monitored_trains when alert state clears
--]]
local function on_state_change(event)
  local train_id = event.train.id
  local new_state = event.train.state

  if data.monitored_trains[train_id] then
    -- remove or update already monitored train
    if ok_states[new_state] then
      stop_monitoring(train_id)
    elseif monitor_states[new_state] and new_state ~= data.monitored_trains[train_id].state then
      update_monitoring(train_id, new_state)
    end
  elseif monitor_states[new_state] then
    start_monitoring(train_id, new_state, event.train)
  end
end
script.on_event(defines.events.on_train_changed_state, on_state_change)

do--[[ on_tick_handler
  * checks alert_queue for a train
  * if one exists, the train is added to the alert UI
  * checks update_queue for a train
  * if one exists, displayed time for that train is updated
  --]]
  local trains_per_tick = defs.constants.trains_per_tick
  local ticks_to_timestring = require("__OpteraLib__.script.misc").ticks_to_timestring
  local function button_params(id)
    return {
      type = "button",
      style = "tral_button_row",
      name = "tral_trainbt_" .. id,
      tooltip = {"tral.button-tooltip"},
    }
  end

  local function on_tick_handler(event)
    -- add train to alert
    local train_id = Queue.pop(data.alert_queue, event.tick)
    if train_id then
      local train_data = data.monitored_trains[train_id]
      if train_data.train.valid then
        data.active_alerts[train_id] = true
        Queue.insert(data.update_queue, event.tick + update_interval, train_id)
        ui.add_row(
          train_id,
          train_state_dict[train_data.state],
          ticks_to_timestring(event.tick - train_data.start_time)
        )
      else
        stop_monitoring(train_id)
      end
    end
    -- update time for active alerts
    train_id = Queue.pop(data.update_queue, event.tick)
    if train_id and data.active_alerts[train_id] then
      local train_data = data.monitored_trains[train_id]
      if train_data.train.valid then
        ui.update_time(train_id, ticks_to_timestring(event.tick - train_data.start_time))
        Queue.insert(data.update_queue, event.tick + update_interval, train_id)
      else
        stop_monitoring(train_id)
      end
    end
  end

  script.on_event(defines.events.on_tick, on_tick_handler)
end

do  -- on_runtime_mod_setting_changed
  local train_state = defines.train_state
  local offset = 2
  local function update_timeouts()
    local set = settings.global
    update_interval = set["tral-refresh-interval"].value
    monitor_states = {}
    ok_states = {
      [train_state.on_the_path] = true,
      [train_state.arrive_station] = true,
    }
    if set["tral-station-timeout"].value >= 0 then
      monitor_states[train_state.wait_station] = set["tral-station-timeout"].value * 60 + offset
    else
      ok_states[train_state.wait_station] = true
    end
    if set["tral-signal-timeout"].value >= 0 then
      monitor_states[train_state.wait_signal] = set["tral-signal-timeout"].value * 60 + offset
    else
      ok_states[train_state.wait_signal] = true
    end
    if set["tral-no-path-timeout"].value >= 0 then
      monitor_states[train_state.no_path] = set["tral-no-path-timeout"].value * 60 + offset
    end
    if set["tral-no-schedule-timeout"].value >= 0 then
      monitor_states[train_state.no_schedule] = set["tral-no-schedule-timeout"].value * 60 + offset
    end
    if set["tral-manual-timeout"].value >= 0 then
      monitor_states[train_state.manual_control] = set["tral-manual-timeout"].value * 60 + offset
    else
      ok_states[train_state.manual_control] = true
      ok_states[train_state.manual_control_stop] = true
    end
    -- update monitored trains
    if data then
      for train_id, train_data in pairs(data.monitored_trains) do
        local state = train_data.state
        if monitor_states[state] then
          update_monitoring(train_id, state)
        else
          stop_monitoring(train_id)
        end
      end
    end
  end
  update_timeouts() -- call once for initial setup

  local function on_settings_changed_handler(event)
    if event.setting and string.match(event.setting, "tral-") then
      debug_log = settings.global["tral-debug-level"].value
      update_timeouts()
      local player = game.players[event.player_index]
      if event.setting == "tral-open-on-alert" then
        global.gui.show_on_alert[event.player_index] = settings.get_player_settings(player)["tral-open-on-alert"].value or nil
      end
      if event.setting == "tral-window-height" then
        ui.player_init(event.player_index)
      end
      log2("Mod settings changed by player", player.name, ".\nSetting changed event:", event, "\nUpdated state dicts:", monitor_states, ok_states)
    end
  end
  script.on_event(defines.events.on_runtime_mod_setting_changed, on_settings_changed_handler)
end

do  -- on_gui_click
  local open_train_gui = require("__OpteraLib__.script.train").open_train_gui
  local tonumber, match = tonumber, string.match
  local handler = {
    [defs.names.gui.elements.ignore_button] = ui.add_to_ignore,
    [defs.names.gui.elements.help_button] = ui.open_help,
  }

  script.on_event(defines.events.on_gui_click,
    function(event)
      if event.element and event.element.name then
        if debug_log then log2("on_gui_click event received:", event) end
        if handler[event.element.name] then
          handler[event.element.name](event)
        else
          local train_id = tonumber(match(event.element.name, "tral_trainbt_(%d+)"))
          if train_id and data.monitored_trains[train_id] then
            if event.button == 2 then -- left mouse button
              open_train_gui(event.player_index, data.monitored_trains[train_id].train)
            else -- right mouse button
              stop_monitoring(train_id)
            end
          end
        end
      end
    end
    )
end

script.on_event(defines.events.on_player_created,
  function(event)
    ui.player_init(event.player_index)
    log2("New player", game.players[event.player_index].name, "created.")
  end
)

do -- on_init, on_load, on_configuration_changed
  local function init_train_states()
    for _, surface in pairs(game.surfaces) do
      local trains = surface.get_trains()
      for _,train in pairs(trains) do
        local train_id = train.id
        local state = train.state
        if monitor_states[state] then
          if state == defines.train_state.wait_station and
            data.ltn_stops and
            monitor_states[defines.train_state.wait_station] then
            -- dont trigger alert fors trains stopped at LTN depots
            local stop_id = train.station and train.station.unit_number
            if stop_id and data.ltn_stops[stop_id] and
                data.ltn_stops[stop_id].isDepot then
              break
            end
          end -- if new_state == train_state.wait_station ...
          local alert_time = game.tick + monitor_states[state]
          alert_time = Queue.insert(data.alert_queue, alert_time, train_id)
          data.monitored_trains[train_id] = {
            state = state,
            start_time = game.tick,
            alert_time = alert_time,
            train = train
          }
        end
      end
    end
  end

  local function get_ltn_stops(event)
    data.ltn_stops = event.logistic_train_stops
  end

  local function register_ltn_event()
    if remote.interfaces["logistic-train-network"] and remote.interfaces["logistic-train-network"].on_stops_updated then
      script.on_event(remote.call("logistic-train-network", "on_stops_updated"), get_ltn_stops)
      return true
    end
    return false
  end

  script.on_init(
    function()
      global.data = {
        monitored_trains = {},
        alert_queue = Queue.new(),
        update_queue = Queue.new(),
        active_alerts = {},
      }
      data = global.data
      ui.init()
      if register_ltn_event() then
        data.ltn_stops = {}
      end
      init_train_states()
      log2("First time initialization finished.\nDebug data dump follows.\n", data)
    end
  )
  script.on_load(
    function()
      data = global.data  -- localize data table
      ui.on_load()  -- localize ui tables
      register_ltn_event()
    end
  )

  script.on_configuration_changed(
    function(event)
      if register_ltn_event() then
        data.ltn_stops = {}
      else
        data.ltn_stops = nil
      end
    end
  )
end
