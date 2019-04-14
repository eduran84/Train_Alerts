-- load modules
log2, print = require("__OpteraLib__.script.logger")()
local ui = require("script.gui_ctrl")

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

-- set parameters and dictionaries
local trains_per_tick = 15
local update_interval = settings.global["tral-refresh-interval"]
local monitor_states, ok_states


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
local function get_ltn_stops(event)
  data.ltn_stops = event.logistic_train_stops
end

local function on_state_change(event)
  local train_id = event.train.id
  local new_state = event.train.state
  if data.monitored_trains[train_id] then
    if ok_states[new_state] then
      data.monitored_trains[train_id] = nil
    elseif monitor_states[new_state] then
      data.monitored_trains[train_id].state = new_state
    end
  else
    if monitor_states[new_state] then
      if proc.ltn_event and monitor_states[train_state.wait_station] and new_state == train_state.wait_station then
        -- dont count trains stopped at LTN depots for station wait timeout
        local stop_id = event.train.station.unit_number
        if not(stop_id and data.ltn_stops[stop_id] and data.ltn_stops[stop_id].isDepot) then
          data.monitored_trains[train_id] = {state = new_state, start_time = game.tick, train = event.train}
        end
      else
        data.monitored_trains[train_id] = {state = new_state, start_time = game.tick, train = event.train}
      end
    end
  end
end
on_event(defines.events.on_train_changed_state, on_state_change)

local function button_params(id)
  return {
    type = "sprite-button",
    style = "recipe_slot_button",
    number = tostring(proc.next_id),
    name = "tral_trainbt_" .. proc.next_id,
    tooltip = {"tral.button-tooltip"}
    sprite = "item/locomotive"
  }
end

local function on_tick_handler(event)
  if proc.state == "init" then
    -- copy monitored trains to processor dataset
    proc.dataset = {}
    for id, train_data in pairs(data.monitored_trains) do
      proc.dataset[id] = train_data
    end
    proc.N = 0
    proc.table_entries = {}
    proc.alert_trains = {}
    proc.alert_state = false
    proc.state = "process"
    proc.next_id = nil
  elseif proc.state == "process" then
    local table_entries = proc.table_entries
    local counter = 0, 0
    local train_data
    local tick = event.tick
    while counter < trains_per_tick do
      proc.next_id, train_data = next(proc.dataset, proc.next_id)
      if proc.next_id then
        counter = counter + 1
        if train_data.train.valid then
          if (tick - train_data.start_time) > monitor_states[train_data.state] then
            table_entries[proc.N+1] = button_params(proc.next_id)
            table_entries[proc.N+2] = {type = "label", style = "description_label", caption = train_state_dict[train_data.state]}
            table_entries[proc.N+3] = {type = "label", style = "description_label", caption = ticks_to_timestring(tick - train_data.start_time)}
            proc.N = proc.N+3
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
    log2("update phase:", global.proc)
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
  --log2("Processor state:", proc)
end

local function start_on_tick(event)
  if proc.state == "idle" then
    proc.state = "init"
    on_event(on_tick_event, on_tick_handler)
  end
end
script.on_nth_tick(update_interval, start_on_tick)

-- initialization and settings
local function on_settings_changed_handler(event)
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
  if event and event.setting == "tral-open-on-alert" then
    proc.show_on_alert[event._player_index] = settings.get_player_settings(game.players[event._player_index])["tral-open-on-alert"].value or nil
  end
  if event and event.setting == "tral-show-button" then
    proc.show_button[event._player_index] = settings.get_player_settings(game.players[event._player_index])["tral-show-button"].value
    ui.player_init(event._player_index)
  end
end
on_settings_changed_handler() -- call once for initial setup
script.on_event(defines.events.on_runtime_mod_setting_changed, on_settings_changed_handler)


local function on_stops_updated(event)
  raw.stops = event.logistic_train_stops
end

script.on_event(defines.events.on_player_created,
  function(event)
    proc.show_on_alert[event.player_index] =  settings.get_player_settings(game.players[event._player_index])["tral-open-on-alert"].value or nil
    proc.show_button[event._player_index] = settings.get_player_settings(game.players[event._player_index])["tral-show-button"].value
    ui.player_init(event.player_index)
  end
)

script.on_init(
  function()
    global.data = {monitored_trains = {}, new_trains = {}}
    global.proc = {state = "idle", show_on_alert = {[1] = true}}
    data = global.data
    proc = global.proc
    for pind, player in pairs(game.players) do
      proc.show_on_alert[pind] =  settings.get_player_settings(player)["tral-open-on-alert"].value or nil
      proc.show_button[pind] = settings.get_player_settings(game.players[pind])["tral-show-button"].value
      ui.player_init(pind)
    end
    if game.active_mods["Logistic-Train-Network"] then
      proc.ltn_event = remote.call("logistic-train-network", "on_stops_updated")
      script.on_event(proc.ltn_event, get_ltn_stops)
    end
  end
)
script.on_load(
  function()
    data = global.data
    proc = global.proc
    if proc.state ~= "idle" then
      on_event(on_tick_event, on_tick_handler)
    end
    if proc.ltn_event then
      script.on_event(proc.ltn_event, get_ltn_stops)
    end
  end
)

script.on_configuration_changed(
  function(event)
    if proc.ltn_event then
      script.on_event(proc.ltn_event, nil)
    end
    if game.active_mods["Logistic-Train-Network"] then
      proc.ltn_event = remote.call("logistic-train-network", "on_stops_updated")
      script.on_event(proc.ltn_event, get_ltn_stops)
    else
      proc.ltn_event = nil
      data.ltn_stops = nil
    end
  end
)
