--localize functions and variables
local Queue = require("script.queue")
local pop, insert = Queue.pop, Queue.insert
local pairs, max = pairs, math.max
local ticks_to_timestring = require("__OpteraLib__.script.misc").ticks_to_timestring
local raise_internal_event = raise_internal_event

local update_interval = settings.global["tral-refresh-interval"].value
local wait_station_state = defines.train_state.wait_station
local trains_per_tick = defs.constants.trains_per_tick
local train_state_dict = defs.dicts.train_state
local ok_states, monitor_states

local data = {
  ltn_stops = nil,
  active_alerts = {},
  monitored_trains = {},
  ignored_trains = {},
  update_queue = Queue.new(),
  alert_queue = Queue.new(),
}

local function stop_monitoring(train_id)
  if data.active_alerts[train_id] then
    raise_internal_event(defs.events.on_alert_expired, train_id)
    data.active_alerts[train_id] = nil
    Queue.remove_value(data.update_queue, train_id)
  end
  Queue.remove_value(data.alert_queue, train_id)
  data.monitored_trains[train_id] = nil
  if debug_mode then
    log2("No longer monitoring train", train_id)
  end
end

local function start_monitoring(train_id, new_state, timeout, train)
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
  insert(data.alert_queue, game.tick + timeout, train_id)
  data.monitored_trains[train_id] = {
    state = new_state,
    start_time = game.tick,
    train = train
  }
  if debug_mode then
    log2("Monitoring train", train_id, "=", data.monitored_trains[train_id])
  end
end

local function update_monitored_train(train_id, new_state, timeout)
  data.monitored_trains[train_id].state = new_state
  if data.active_alerts[train_id] then
    raise_internal_event(
      defs.events.on_state_updated,
      {
        name = "state",
        train_id = train_id,
        new_value = train_state_dict[new_state],
      }
    )
  else
    -- recalculate alert time
    Queue.remove_value(data.alert_queue, train_id)
    insert(
      data.alert_queue,
      max(data.monitored_trains[train_id].start_time + timeout, game.tick+2),
      train_id
    )
  end
  if debug_mode then
    log2("Updated train", train_id, "=", data.monitored_trains[train_id])
  end
end

local function full_state_check(train)
  local train_id = train.id
  local new_state = train.state
  local is_ok, timeout
  if data.ignored_trains[train_id] then
    is_ok = data.ignored_trains[train_id].ok_states[new_state]
    timeout = data.ignored_trains[train_id].monitor_states[new_state]
  else
    is_ok = ok_states[new_state]
    timeout = monitor_states[new_state]
  end
  if data.monitored_trains[train_id] then
    if is_ok then
      stop_monitoring(train_id)
    elseif timeout then
      update_monitored_train(train_id, new_state, timeout)
    end
  elseif timeout then
    start_monitoring(train_id, new_state, timeout, train)
  end

end

--[[ on_state_change
* triggered on_train_changed_state
* adds trains with potential alert states to data.monitored_trains
* removes trains from data.monitored_trains when alert state clears
--]]

local function on_train_changed_state(event)
  local train_id = event.train.id
  local new_state = event.train.state
  local is_ok, timeout
  if data.ignored_trains[train_id] then
    is_ok = data.ignored_trains[train_id].ok_states[new_state]
    timeout = data.ignored_trains[train_id].monitor_states[new_state]
  else
    is_ok = ok_states[new_state]
    timeout = monitor_states[new_state]
  end
  if data.monitored_trains[train_id] then
    -- remove or update already monitored train
    if is_ok then
      stop_monitoring(train_id)
    elseif timeout and new_state ~= data.monitored_trains[train_id].state then
      update_monitored_train(train_id, new_state, timeout)
    end
  elseif timeout and not data.ignored_trains[train_id] then
    start_monitoring(train_id, new_state, timeout, event.train)
  end
end

--[[ on_tick
  * checks alert_queue for a train
  * if one exists, the train is added to the alert UI
  * checks update_queue for a train
  * if one exists, displayed time for that train is updated
  --]]
local function button_params(id)
  return {
    type = "button",
    style = "tral_button_row",
    name = "tral_trainbt_" .. id,
    tooltip = {"tral.button-tooltip"},
  }
end
local on_new_alert = defs.events.on_new_alert
local function on_tick(event)
  -- add train to alert
  local train_id = pop(data.alert_queue, event.tick)
  if train_id then
    local train_data = data.monitored_trains[train_id]
    if train_data.train.valid then
      data.active_alerts[train_id] = true
      insert(data.update_queue, event.tick + update_interval, train_id)
      raise_internal_event(
        on_new_alert,
        {
          train_id = train_id,
          state = train_state_dict[train_data.state],
          time = ticks_to_timestring(event.tick - train_data.start_time)
        }
      )
    else
      stop_monitoring(train_id)
    end
  end
  -- update time for active alerts
  train_id = pop(data.update_queue, event.tick)
  if train_id and data.active_alerts[train_id] then
    local train_data = data.monitored_trains[train_id]
    if train_data.train.valid then
      raise_internal_event(
        defs.events.on_state_updated,
        {
          name = "time",
          train_id = train_id,
          new_value = ticks_to_timestring(event.tick - train_data.start_time),
        }
      )
      insert(data.update_queue, event.tick + update_interval, train_id)
    else
      stop_monitoring(train_id)
    end
  end
end

local function init_train_states()
  for _, surface in pairs(game.surfaces) do
    local trains = surface.get_trains()
    for _,train in pairs(trains) do
      local train_id = train.id
      local state = train.state
      -- fire a fake on_train_state_changed for every existing train
      on_train_changed_state({train = train})
    end
  end
end

local train_state = defines.train_state
local offset = 2
local names = defs.names.settings
local function update_timeouts()
  local set = settings.global
  update_interval = set[names.refresh_interval].value
  monitor_states = {}
  ok_states = {
    [train_state.on_the_path] = true,
    [train_state.arrive_station] = true,
  }
  if set[names.timeout_station].value >= 0 then
    monitor_states[train_state.wait_station] = set[names.timeout_station].value * 60 + offset
  else
    ok_states[train_state.wait_station] = true
  end
  if set[names.timeout_signal].value >= 0 then
    monitor_states[train_state.wait_signal] = set[names.timeout_signal].value * 60 + offset
  else
    ok_states[train_state.wait_signal] = true
  end
  if set[names.timeout_path].value >= 0 then
    monitor_states[train_state.no_path] = set[names.timeout_path].value * 60 + offset
  end
  if set[names.timeout_schedule].value >= 0 then
    monitor_states[train_state.no_schedule] = set[names.timeout_schedule].value * 60 + offset
  end
  if set[names.timeout_manual].value >= 0 then
    monitor_states[train_state.manual_control] = set[names.timeout_manual].value * 60 + offset
  else
    ok_states[train_state.manual_control] = true
    ok_states[train_state.manual_control_stop] = true
  end
  -- update monitored trains
  -- TODO add update for un-monitored trains
end

local function on_settings_changed(event)
    if event.setting and string.match(event.setting, "tral-timeout-") then
      update_timeouts()
      init_train_states()
      log2("Mod settings changed by player", game.players[event.player_index].name, ".\nSetting changed event:", event, "\nUpdated state dicts:", monitor_states, ok_states)
    end
end

local events =
{
  [defines.events.on_train_changed_state] = on_train_changed_state,
  [defines.events.on_tick] = on_tick,
  [defines.events.on_runtime_mod_setting_changed] = on_settings_changed,
}
local internal_events =
{
  [defs.events.on_alert_removed] = stop_monitoring,
}
-- public module API
local train_state_monitor = {}

function train_state_monitor.on_init()
  global.train_state_monitor = global.train_state_monitor or data
  update_timeouts()
end

function train_state_monitor.on_load()
  data = global.train_state_monitor
  update_timeouts()
end

function train_state_monitor.get_events()
  return events
end

function train_state_monitor.get_internal_events()
  return internal_events
end

function train_state_monitor.on_configuration_changed(data)
end

return train_state_monitor