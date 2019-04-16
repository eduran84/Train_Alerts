-- load modules
local log2 = require("__OpteraLib__.script.logger").log
local ui = require("script.gui_ctrl")

-- set parameters and dictionaries
debug_log = settings.global["tral-debug-level"].value
local update_interval = settings.global["tral-refresh-interval"]
local trains_per_tick = 15
local monitor_states, ok_states

--localize functions
local next, pairs, format, tostring = next, pairs, string.format, tostring
local on_event = script.on_event
local ticks_to_timestring
do
  ticks_to_timestring = require("__OpteraLib__.script.misc").ticks_to_timestring
end

-- localize variables
local data, proc
local on_tick_event = defines.events.on_tick
local train_state = defines.train_state

local train_state_dict = {
  [train_state.on_the_path] = {"train-states.on_the_path"},
  [train_state.path_lost] = {"train-states.path_lost"},
  [train_state.no_schedule] = {"train-states.no_schedule"},
  [train_state.no_path] = {"train-states.no_path"},
  [train_state.arrive_signal] = {"train-states.arrive_signal"},
  [train_state.wait_signal] = {"train-states.wait_signal"},
  [train_state.arrive_station] = {"train-states.arrive_station"},
  [train_state.wait_station] = {"train-states.wait_station"},
  [train_state.manual_control_stop] = {"train-states.manual_control_stop"},
  [train_state.manual_control] = {"train-states.manual_control"},
}

-- runtime code
do--[[ on_state_change
  * triggered on_train_changed_state
  * adds trains with potential alert states to data.monitored_trains
  * removes trains from data.monitored_trains when alert state clears
  --]]
  local function on_state_change(event)
    local train_id = event.train.id
    local new_state = event.train.state
    if data.monitored_trains[train_id] then
      -- train already monitored, remove or update depending on new_state
      if ok_states[new_state] then
        data.monitored_trains[train_id] = nil
        if debug_log then log2("No longer monitoring train", train_id) end
      elseif monitor_states[new_state] then
        data.monitored_trains[train_id].state = new_state
        if debug_log then log2("Updated train", train_id, ". New dataset:", data.monitored_trains[train_id]) end
      end
    else
      if monitor_states[new_state] then
        -- train not monitored, but should be
        if data.ltn_stops and monitor_states[train_state.wait_station] and new_state == train_state.wait_station then
          -- dont trigger alert fors trains stopped at LTN depots
          local stop_id = event.train.station and event.train.station.unit_number
          if not(stop_id and data.ltn_stops[stop_id] and data.ltn_stops[stop_id].isDepot) then
            data.monitored_trains[train_id] = {state = new_state, start_time = game.tick, train = event.train}
            if debug_log then log2("Monitoring train", train_id, ". Dataset:", data.monitored_trains[train_id]) end
          end
        else
          data.monitored_trains[train_id] = {state = new_state, start_time = game.tick, train = event.train}
          if debug_log then log2("Monitoring train", train_id, ". Dataset:", data.monitored_trains[train_id]) end
        end
      end
    end
  end
  on_event(defines.events.on_train_changed_state, on_state_change)
end

local on_tick_handler
do--[[ on_tick_handler
  * after being started by start_on_tick function, this runs on every
    tick until all monitored trains are processed
  * states:
      idle:    not running
      init:    resetting data
      process: check monitored trains against timeout values
               create UI entries for train which are timed out
      update:  update visible UIs with new data
  --]]
  local function button_params(id)
    return {
      type = "button",
      style = "tral_button_row",
      name = "tral_trainbt_" .. proc.next_id,
      tooltip = {"tral.button-tooltip"},
    }
  end

  on_tick_handler = function(event)
    if proc.state == "init" then
      -- copy monitored trains to processor dataset
      proc.dataset = {}
      for id, train_data in pairs(data.monitored_trains) do
        proc.dataset[id] = train_data
      end
      -- reset processor data
      proc.N = 0
      proc.table_entries = {}
      proc.alert_trains = {}
      proc.alert_state = false
      proc.state = "process"
      proc.next_id = nil
      if debug_log then log2("Starting data processing.\nTrains to process:", proc.dataset) end
    elseif proc.state == "process" then
      local table_entries = proc.table_entries
      local counter = 0
      local train_data
      local tick = event.tick
      while counter < trains_per_tick do
        proc.next_id, train_data = next(proc.dataset, proc.next_id)
        if proc.next_id then
          counter = counter + 1
          if train_data.train.valid then
            -- check if train is timed out
            if (tick - train_data.start_time) > monitor_states[train_data.state] then
              table_entries[proc.N] = {button = button_params(proc.next_id)}
              table_entries[proc.N].label = {[1] = {type = "label", style = "tral_label_id", caption = tostring(proc.next_id)}}
              table_entries[proc.N].label[2] = {type = "label", style = "tral_label_state", caption = train_state_dict[train_data.state]}
              table_entries[proc.N].label[3] = {type = "label", style = "tral_label_time", caption = ticks_to_timestring(tick - train_data.start_time)}
              proc.N = proc.N+1
              proc.alert_trains[proc.next_id] = train_data.train
              if not train_data.alert_triggered then
                train_data.alert_triggered = true
                proc.alert_state = true
              end
            end
          else
            data.monitored_trains[proc.next_id] = nil
          end
        else
          proc.state = "update"
          break
        end
      end

    elseif proc.state == "update" then
      if proc.alert_state then
        for pind in pairs(game.players) do
          if proc.show_on_alert[pind] then
            ui.show(pind)
          else
            ui.set_alert_state(true, pind)
          end
        end
      end
      ui.set_table_entires(proc.table_entries)
      on_event(on_tick_event, nil)
      proc.state = "idle"
    end
  end
end

do--[[ start_on_tick
  * starts on_tick_handler every update_interval ticks
  --]]
  local function start_on_tick(event)
    if proc.state == "idle" then
      proc.state = "init"
      on_event(on_tick_event, on_tick_handler)
    end
  end
  script.on_nth_tick(update_interval, start_on_tick)
end

-- initialization and settings
do
  local function update_timeouts()
    local set = settings.global
    update_interval = set["tral-refresh-interval"]
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
      monitor_states[train_state.manual_control_stop] = true
    end
  end
  update_timeouts() -- call once for initial setup

  local function on_settings_changed_handler(event)
    if event.setting and string.match(event.setting, "tral-") then
      debug_log = settings.global["tral-debug-level"].value
      update_timeouts()
      local player = game.players[event.player_index]
      if event.setting == "tral-open-on-alert" then
        proc.show_on_alert[event.player_index] = settings.get_player_settings(player)["tral-open-on-alert"].value or nil
      end
      if event.setting == "tral-show-button" or event.setting == "tral-window-height" then
        proc.show_button[event.player_index] = settings.get_player_settings(player)["tral-show-button"].value
        ui.player_init(event.player_index)
      end
      log2("Mod settings changed by player", player.name, ".\nSetting changed event:", event, "\nUpdated state dicts:", monitor_states, ok_states)
    end
  end
  script.on_event(defines.events.on_runtime_mod_setting_changed, on_settings_changed_handler)
end


script.on_event(defines.events.on_player_created,
  function(event)
    local player = game.players[event.player_index]
    proc.show_on_alert[event.player_index] =  settings.get_player_settings(player)["tral-open-on-alert"].value or nil
    proc.show_button[event.player_index] = settings.get_player_settings(player)["tral-show-button"].value
    ui.player_init(event.player_index)
    log2("New player", player.name, "created.")
  end
)

do
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
      global.data = {monitored_trains = {}, new_trains = {}}
      global.proc = {state = "idle", show_on_alert = {}, show_button = {}}
      data = global.data
      proc = global.proc
      for pind, player in pairs(game.players) do
        proc.show_on_alert[pind] =  settings.get_player_settings(player)["tral-open-on-alert"].value or nil
        proc.show_button[pind] = settings.get_player_settings(player)["tral-show-button"].value
        ui.player_init(pind)
      end
      if register_ltn_event() then
        data.ltn_stops = {}
      end
      log2("First time initialization finished.\nDebug data dump follows.\n", data, proc)
    end
  )
  script.on_load(
    function()
      data = global.data
      proc = global.proc
      if proc.state ~= "idle" then
        on_event(on_tick_event, on_tick_handler)
      end
      register_ltn_event()
      log2("On_load finished.\nDebug data dump follows.\n", data, proc)
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
        ui.player_init()
        proc.ltn_event = nil
      end
    end
  )
end

