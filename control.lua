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
local ui = require("script.gui_ctrl")
local Queue = require("script.queue")

--localize functions and variables
local update_interval = settings.global["tral-refresh-interval"].value
local monitor_states, ok_states
local data
local pairs = pairs
local function remove_monitored_train(train_id)
  if data.active_alerts[train_id] then
    ui.delete_row(train_id)
    data.active_alerts[train_id] = nil
  end
  data.monitor_queue[data.monitored_trains[train_id].alert_time or 0] = nil
  data.monitored_trains[train_id] = nil
end

do--[[ on_state_change
  * triggered on_train_changed_state
  * adds trains with potential alert states to data.monitored_trains
  * removes trains from data.monitored_trains when alert state clears
  --]]

  local wait_station_state = defines.train_state.wait_station
  local function on_state_change(event)
    local train_id = event.train.id
    local new_state = event.train.state

    if data.monitored_trains[train_id] then
      -- remove or update already monitored train
      if ok_states[new_state] then
        remove_monitored_train(train_id)
        if debug_log then log2("No longer monitoring train", train_id) end
      elseif monitor_states[new_state] then
        data.monitored_trains[train_id].state = new_state
        if debug_log then
          log2("Updated train", train_id, ". New dataset:", data.monitored_trains[train_id])
        end
      end

    elseif monitor_states[new_state] then
      --- add unmonitored train to monitor list
      if new_state == wait_station_state and
          data.ltn_stops and
          monitor_states[wait_station_state] then
        -- dont trigger alert fors trains stopped at LTN depots
        local stop_id = event.train.station and event.train.station.unit_number
        if stop_id and data.ltn_stops[stop_id] and
            data.ltn_stops[stop_id].isDepot then
          return
        end
      end -- if new_state == train_state.wait_station ...
      local alert_time = game.tick + monitor_states[new_state]
      alert_time = Queue.insert(data.monitor_queue, alert_time, train_id)
      data.monitored_trains[train_id] = {
        state = new_state,
        start_time = game.tick,
        alert_time = alert_time,
        train = event.train
      }
      if debug_log then
        log2("Monitoring train", train_id, ". Dataset:", data.monitored_trains[train_id])
      end
    end -- elseif monitor_states[new_state]
  end -- function on_state_change

  script.on_event(defines.events.on_train_changed_state, on_state_change)
end

do--[[ on_tick_handler
  * checks monitor_queue for a train
  * if one exists, the train is added to the alert UI
  * checks update_queue for a train
  * if one exists, displayed time for that train is updated
  --]]

  local trains_per_tick = defs.constants.trains_per_tick
  local train_state_dict = defs.dicts.train_state
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
    local train_id = Queue.pop(data.monitor_queue, event.tick)
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
        remove_monitored_train(train_id)
      end
    end

    -- update time for active alerts
    train_id = Queue.pop(data.update_queue, event.tick)
    if train_id then
      local train_data = data.monitored_trains[train_id]
      if train_data and train_data.train.valid then
        ui.update_row(train_id, ticks_to_timestring(event.tick - train_data.start_time))
        Queue.insert(data.update_queue, event.tick + update_interval, train_id)
      end
    end
  end

  script.on_event(defines.events.on_tick, on_tick_handler)
end

do  -- on_runtime_mod_setting_changed
  local train_state = defines.train_state
  local function update_timeouts()
    local set = settings.global
    update_interval = set["tral-refresh-interval"].value
    monitor_states = {}
    ok_states = {
      [train_state.on_the_path] = true,
      [train_state.arrive_station] = true,
    }
    if set["tral-station-timeout"].value >= 0 then
      monitor_states[train_state.wait_station] = set["tral-station-timeout"].value * 60
    else
      ok_states[train_state.wait_station] = true
    end
    if set["tral-signal-timeout"].value >= 0 then
      monitor_states[train_state.wait_signal] = set["tral-signal-timeout"].value * 60
    else
      ok_states[train_state.wait_signal] = true
    end
    if set["tral-no-path-timeout"].value >= 0 then
      monitor_states[train_state.no_path] = set["tral-no-path-timeout"].value * 60
      monitor_states[train_state.path_lost] = set["tral-no-path-timeout"].value * 60
    end
    if set["tral-no-schedule-timeout"].value >= 0 then
      monitor_states[train_state.no_schedule] = set["tral-no-schedule-timeout"].value * 60
    end
    if set["tral-manual-timeout"].value >= 0 then
      monitor_states[train_state.manual_control] = set["tral-manual-timeout"].value * 60
      monitor_states[train_state.manual_control_stop] = set["tral-manual-timeout"].value * 60
    else
      ok_states[train_state.manual_control] = true
      ok_states[train_state.manual_control_stop] = true
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

  script.on_event(defines.events.on_gui_click,
    function(event)
      if event.element and event.element.name then
        if debug_log then log2("on_gui_click event received:", event) end
        local train_id = tonumber(match(event.element.name, "tral_trainbt_(%d+)"))
        if train_id and data.monitored_trains[train_id] then
          if event.button == 2 then -- left mouse button
            open_train_gui(event.player_index, data.monitored_trains[train_id].train)
          else -- right mouse button
            remove_monitored_train(train_id)
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
        monitor_queue = {},
        update_queue = {},
        active_alerts = {},
      }
      data = global.data
      ui.init()
      if register_ltn_event() then
        data.ltn_stops = {}
      end
      log2("First time initialization finished.\nDebug data dump follows.\n", data)
    end
  )
  script.on_load(
    function()
      data = global.data
      ui.on_load()
      register_ltn_event()
      if debug_log then
        log2("On_load finished.\nDebug data dump follows.\n", data)
      end
    end
  )

  script.on_configuration_changed(
    function(event)
      if register_ltn_event() then
        data.ltn_stops = {}
      else
        data.ltn_stops = nil
      end
      if event.mod_changes["Train_Alerts"] then
        ui.init()
      end
    end
  )
end

