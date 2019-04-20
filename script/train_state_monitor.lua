--[[ Copyright (c) 2019 Eduran
 * Part of Train Alerts GUI
 *
 * See LICENSE.md in the project directory for license information.
--]]

local Queue = require("script.queue")
local ui = require("script.gui_alert_window")

function stop_monitoring(train_id)
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

local wait_station_state = defines.train_state.wait_station
function start_monitoring(train_id, new_state, timeout, train)
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
  Queue.insert(data.alert_queue, game.tick + timeout, train_id)
  data.monitored_trains[train_id] = {
    state = new_state,
    start_time = game.tick,
    train = train
  }
  if debug_log then
    log2("Monitoring train", train_id, "=", data.monitored_trains[train_id])
  end
end

local max = math.max
function update_monitored_train(train_id, new_state, timeout)
  data.monitored_trains[train_id].state = new_state
  if data.active_alerts[train_id] then
    ui.update_state(train_id, new_state)
  else
    -- recalculate alert time
    Queue.remove_value(data.alert_queue, train_id)
    Queue.insert(
      data.alert_queue,
      max(data.monitored_trains[train_id].start_time + timeout, game.tick+2),
      train_id
    )
  end
  if debug_log then
    log2("Updated train", train_id, "=", data.monitored_trains[train_id])
  end
end

function full_state_check(train)
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
local ok_states = ok_states
local monitor_states = monitor_states
function train_changed_state_handler(event)
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
      update_monitored_train(train_id, new_state)
    end
  elseif timeout and not data.ignored_trains[train_id] then
    start_monitoring(train_id, new_state, timeout, event.train)
  end
end
script.on_event(defines.events.on_train_changed_state, train_changed_state_handler)