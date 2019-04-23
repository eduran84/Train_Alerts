--localize functions and variables
local Queue = require(defs.pathes.modules.queue)
local pop, insert = Queue.pop, Queue.insert
local pairs, max = pairs, math.max
local ticks_to_timestring = util.misc.ticks_to_timestring
local raise_private_event = raise_private_event

local update_interval = settings.global[defs.names.settings.refresh_interval].value * 60
local wait_station_state = defines.train_state.wait_station
local trains_per_tick = defs.constants.trains_per_tick
local train_state_dict = defs.dicts.train_state
local timeout_values

local data = {
  ltn_stops = {},
  active_alerts = {},
  monitored_trains = {},
  ignored_trains = {},
  update_queue = Queue.new(),
  alert_queue = Queue.new(),
}
shared.train_state_monitor = {
  timeout_states = {}
}

local function stop_monitoring(train_id)
  if data.active_alerts[train_id] then
    raise_private_event(defs.events.on_alert_expired, train_id)
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
      timeout_values[wait_station_state] >= 0 then
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
  local train_data = data.monitored_trains[train_id]
  train_data.state = new_state
  if data.active_alerts[train_id] then
    raise_private_event(
      defs.events.on_state_updated,
      {
        name = "state",
        train_id = train_id,
        state = train_state_dict[new_state],
        time = ticks_to_timestring(game.tick - train_data.start_time)
      }
    )
  else
    -- recalculate alert time
    Queue.remove_value(data.alert_queue, train_id)
    insert(
      data.alert_queue,
      max(train_data.start_time + timeout, game.tick+2),
      train_id
    )
  end
  if debug_mode then
    log2("Updated train", train_id, "=", data.monitored_trains[train_id])
  end
end

local function full_state_check(event)
  local train = event.train
  local train_id = train.id
  local new_state = train.state
  local train_data = data.ignored_trains[train_id]
  local timeout
  if train_data and train_data.timeout_values then
    timeout = train_data.timeout_values[new_state]
  else
    timeout = timeout_values[new_state]
  end
  log2("full state check:", event, "\ntrain data:", train_data, "new state:", new_state)
  if not timeout then return end
  if data.monitored_trains[train_id] then
    if timeout == -1 then
      stop_monitoring(train_id)
    else
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
  local timeout
  if data.ignored_trains[train_id] and data.ignored_trains[train_id].timeout_values then
    timeout = data.ignored_trains[train_id].timeout_values[new_state]
  else
    timeout = timeout_values[new_state]
  end
  if debug_mode then
    log2("Train changed state.\nEvent:", event, "\ntimeout =", timeout, "\ntrain data:", data.monitored_trains[train_id])
  end
  if not timeout then return end
  if data.monitored_trains[train_id] then
    -- remove or update already monitored train
    if timeout == -1 then
      stop_monitoring(train_id)
    elseif new_state ~= data.monitored_trains[train_id].state then
      update_monitored_train(train_id, new_state, timeout)
    end
  else
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
      raise_private_event(
        on_new_alert,
        {
          train_id = train_id,
          state = train_state_dict[train_data.state],
          time = ticks_to_timestring(event.tick - train_data.start_time),
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
      raise_private_event(
        defs.events.on_state_updated,
        {
          name = "time",
          train_id = train_id,
          state = train_state_dict[train_data.state],
          time = ticks_to_timestring(event.tick - train_data.start_time),
        }
      )
      insert(data.update_queue, event.tick + update_interval, train_id)
    else
      stop_monitoring(train_id)
    end
  end
end

local function register_ltn_event()
  if remote.interfaces["logistic-train-network"] and remote.interfaces["logistic-train-network"].on_stops_updated then
    script.on_event(
      remote.call("logistic-train-network", "on_stops_updated"),
      function(event)
        data.ltn_stops = event.logistic_train_stops
      end
    )
    return true
  end
  return false
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
local offset = defs.constants.timeout_offset
local names = defs.names.settings
local timout_names = {
  [names.timeout_station] = train_state.wait_station,
  [names.timeout_signal] = train_state.wait_signal,
  [names.timeout_path] = train_state.no_path,
  [names.timeout_schedule] = train_state.no_schedule,
  [names.timeout_manual] = train_state.manual_control,
}
local function update_timeouts()
  local set = settings.global
  update_interval = set[names.refresh_interval].value * 60
  timeout_values = {
    [train_state.on_the_path] = -1,
    [train_state.arrive_station] = -1
  }
  for setting_name, train_state in pairs(timout_names) do
    local setting_value = set[setting_name].value
    if setting_value ~= -1 then
      setting_value = setting_value * 60 + offset
    end
    timeout_values[train_state] = setting_value
  end
  shared.train_state_monitor.timeout_values = timeout_values
end

local function on_settings_changed(event)
  if event.setting and string.match(event.setting, names.tsm_prefix) then
    update_timeouts()
    log2("Mod settings changed by player", game.players[event.player_index].name, ".\nSetting changed event:", event, "\nUpdated timeouts:",timeout_values)
    init_train_states()
  end
end

local events =
{
  [defines.events.on_train_changed_state] = on_train_changed_state,
  [defines.events.on_tick] = on_tick,
  [defines.events.on_runtime_mod_setting_changed] = on_settings_changed,
}
local private_events =
{
  [defs.events.on_alert_removed] = stop_monitoring,
  [defs.events.on_timeouts_modified] = full_state_check,
}
-- public module API
local train_state_monitor = {}

function train_state_monitor.on_init()
  global.train_state_monitor = global.train_state_monitor or data
  update_timeouts()
  register_ltn_event()
end

function train_state_monitor.on_load()
  data = global.train_state_monitor
  update_timeouts()
  register_ltn_event()
end

function train_state_monitor.get_events()
  return events
end

function train_state_monitor.get_private_events()
  return private_events
end

function train_state_monitor.on_configuration_changed(data)
  if register_ltn_event() then
    data.ltn_stops = data.ltn_stops or {}
  else
    data.ltn_stops = {}
  end
end

return train_state_monitor