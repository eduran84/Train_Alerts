--localize functions and variables
local queue = util.queue
local pop, insert = queue.pop, queue.insert
local pairs, max = pairs, math.max
local ticks_to_timestring = util.misc.ticks_to_timestring
local raise_private_event = raise_private_event

local update_interval = settings.global[defs.names.settings.refresh_interval].value * 60
local wait_station_state, wait_signal_state = defines.train_state.wait_station, defines.train_state.wait_signal
local trains_per_tick = defs.constants.trains_per_tick
local train_state_dict = defs.dicts.train_state
local on_new_alert = defs.events.on_new_alert
local timeout_values

-- localize access to relevant global variables
local st
local data = {
  ltn_stops = {},
  --[[ stop_id :: stop_data: table with data about stop ]]
  active_alerts = {},
  --[[ train_id :: bool: true if train_id is listed in alerts window ]]
  monitored_trains = {},
  --[[ Monitored trains are all train in alert states, even if their timout has not expired.
      train_id :: table: train state information for monitored train
        * state :: uint: current train state
        * start_time :: uint: time in game ticks when the state change was detected
        * train :: LuaTrain: monitored train ]]
  ignored_trains = {},
  --[[ Trains added to the exception list with modified timout values.
      train_id :: table: train setting information
        * train :: LuaTrain: monitored train
        * timeout_values :: table mapping train state to modified timeout value ]]
  alert_queue = queue.new(),
  -- trains queued up for an alert when their timeout expires
  update_queue = queue.new(),
  -- trains on the alert list, queued up for an update of their state
}
shared.train_state_monitor = {
  timeout_values = {}
}

-- helper functions
local function is_stop_ignored(stop_entity)
  local stop_id = stop_entity and stop_entity.valid and stop_entity.unit_number
  return  (data.ltn_stops[stop_id] and data.ltn_stops[stop_id].isDepot)
          or (st.selected_entities[stop_id])
end

local function stop_monitoring(train_id)
  if data.active_alerts[train_id] then
    raise_private_event(defs.events.on_alert_expired, train_id)
    data.active_alerts[train_id] = nil
    queue.remove_value(data.update_queue, train_id)
  else
    queue.remove_value(data.alert_queue, train_id)
  end
  data.monitored_trains[train_id] = nil
  if debug_mode then
    log2("No longer monitoring train", train_id)
  end
end

local function start_monitoring(train, new_state, timeout)
  local train_id = train.id
  if new_state == wait_station_state and is_stop_ignored(train.station)
    then return -- no alerts fors trains stopped at LTN depots and ignored stations
  elseif new_state == wait_signal_state and train.signal
      and train.signal.valid and st.selected_entities[train.signal.unit_number]
    then return -- no alerts for ignored signals
  end
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
  train_data.start_time = game.tick
  if data.active_alerts[train_id] then
    -- disable active alert
    raise_private_event(defs.events.on_alert_expired, train_id)
    data.active_alerts[train_id] = nil
    queue.remove_value(data.update_queue, train_id)
  else
    -- recalculate alert time
    queue.remove_value(data.alert_queue, train_id)
  end
  insert(data.alert_queue, game.tick + timeout, train_id)
  if debug_mode then
    log2("Updated train", train_id, "=", data.monitored_trains[train_id])
  end
end


local function on_train_changed_state(event)--[[
  Adds trains with potential alert states to data.monitored_trains and
  removes trains from data.monitored_trains when alert state clears.

  Parameters
    event :: table with fields
        train :: LuaTrain
        old_state :: defines.train_state (optional)
        force :: boolean (optional)
  ]]
  local train_id = event.train.id
  local new_state = event.train.state
  local timeout
  -- timeout == nil means this state is OK, timeout >= 0 means this becomes alert after timeout ticks
  if data.ignored_trains[train_id] and data.ignored_trains[train_id].timeout_values then
    timeout = data.ignored_trains[train_id].timeout_values[new_state]
  else
    timeout = timeout_values[new_state]
  end
  if debug_mode then
    log2("Train changed state from", train_state_dict[event.old_state],
      "to", train_state_dict[new_state], "\ntimeout =", timeout,
      "\nEvent:", event, "\ntrain data:", data.monitored_trains[train_id])
  end
  if timeout then
    if data.monitored_trains[train_id] then
      -- remove or update already monitored train
      if new_state ~= data.monitored_trains[train_id].state or event.force then
        update_monitored_train(train_id, new_state, timeout) -- switch from one alert state to another
      end
    else
      start_monitoring(event.train, new_state, timeout)
    end
  elseif data.monitored_trains[train_id] then
    stop_monitoring(train_id)
  end
end


local function on_train_created(event)
  --[[ Called when a new train is created either through disconnecting/connecting an existing one or building a new one.
  Contains
  train :: LuaTrain
  old_train_id_1 :: uint (optional): The first old train id when splitting/merging trains.
  old_train_id_2 :: uint (optional): The second old train id when splitting/merging trains.
  --]]
  local new_train_id = event.train.id
  local old_train_id_1 = event.old_train_id_1
  local old_train_id_2 = event.old_train_id_2
  if old_train_id_1 then
    if data.ignored_trains[old_train_id_1] then
      data.ignored_trains[new_train_id] = data.ignored_trains[old_train_id_1]
      raise_private_event(defs.events.on_train_does_not_exist, {train_id = old_train_id_1})
    end
    stop_monitoring(old_train_id_1)
  end
  if old_train_id_2 then
    stop_monitoring(event.old_train_id_2)
    if data.ignored_trains[old_train_id_2] then
      data.ignored_trains[new_train_id] = data.ignored_trains[new_train_id] or data.ignored_trains[old_train_id_2]
      raise_private_event(defs.events.on_train_does_not_exist, {train_id = old_train_id_2})
    end
  end
  if data.ignored_trains[new_train_id] then
    raise_private_event(defs.events.on_train_ignored, {train_id = new_train_id})
  end
  on_train_changed_state({train = event.train})
end

local function on_tick(event)
  --[[ on_tick
  * checks alert_queue for a train
  * if one exists, the train is added to the alert UI
  * checks update_queue for a train
  * if one exists, displayed time for that train is updated
  --]]
  local train_id = pop(data.alert_queue, event.tick)
  if train_id then
    local train_data = data.monitored_trains[train_id]
    if not train_data then log2("train_id:", train_id); error() end
    local train = train_data.train
    if train.valid and not is_stop_ignored(train.station) then
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
script.on_event(defines.events.on_tick, on_tick)

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

local train_state = defines.train_state
local offset = defs.constants.timeout_offset
local names = defs.names.settings
local function register_on_damaged_event()
  if true then return end  -- currently disabled
  if settings.global[names.alert_on_damage].value then
    script.on_event(defines.events.on_entity_damaged, on_entity_damaged)
  else
    script.on_event(defines.events.on_entity_damaged, nil)
  end
end

local function init_train_states()
  for _, surface in pairs(game.surfaces) do
    local trains = surface.get_trains()
    for _,train in pairs(trains) do
      -- fire a fake on_train_state_changed for every existing train
      on_train_changed_state({train = train, force = true})
    end
  end
end

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
  timeout_values = {}
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
    log2("Mod setting", event.setting, "changed to", settings.global[event.setting].value,
      "by player", game.players[event.player_index].name,
      ".\nSetting changed event:", event, "\nUpdated timeouts:",timeout_values)
    init_train_states()
    if event.setting == names.alert_on_damage then
      register_on_damaged_event()
    end
  end
end

-- public module API --

local events =
{
  --[defines.events.on_tick] = on_tick, -- not handled by event system to avoid overhead in on_tick
  [defines.events.on_train_changed_state] = on_train_changed_state,
  [defines.events.on_runtime_mod_setting_changed] = on_settings_changed,
  [defines.events.on_train_created] = on_train_created
}
local private_events =
{
  [defs.events.on_alert_removed] = stop_monitoring,
  [defs.events.on_timeouts_modified] = on_train_changed_state,
}

local train_state_monitor = {}

function train_state_monitor.on_init()
  global.train_state_monitor = global.train_state_monitor or data
  st = global.selection_tool
  update_timeouts()
  register_ltn_event()
  register_on_damaged_event()
end

function train_state_monitor.on_load()
  data = global.train_state_monitor
  st = global.selection_tool
  update_timeouts()
  register_ltn_event()
  register_on_damaged_event()
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
  local mod_data = data.mod_changes[defs.names.mod_name]
  if mod_data and util.is_version_below(mod_data.old_version, "0.3.1") then
    settings.global[names.refresh_interval].value = 1
    update_timeouts()
    init_train_states()
  end
end

return train_state_monitor