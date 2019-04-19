--[[ Copyright (c) 2019 Eduran
 * Part of Train Alerts GUI
 *
 * See LICENSE.md in the project directory for license information.
--]]

-- Wipe old UI
local mg = require("mod-gui")
local frame_name = "tral-frame"
for pind, player in pairs(game.players) do
  if mg.get_frame_flow(player)["tral-frame"] and mg.get_frame_flow(player)["tral-frame"].valid then
    mg.get_frame_flow(player)["tral-frame"].destroy()
  end
  if mg.get_button_flow(player)["tral_toggle_button"] and mg.get_button_flow(player)["tral_toggle_button"].valid then
    mg.get_button_flow(player)["tral_toggle_button"].destroy()
  end
end

-- Wipe old data structure and rebuild
local Queue = require("script.Queue")
local data, monitor_states, ok_states
local train_state = defines.train_state
local offset = 2
local function update_timeouts()
  local set = settings.global
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
    monitor_states[train_state.path_lost] = set["tral-no-path-timeout"].value * 60 + offset
  end
  if set["tral-no-schedule-timeout"].value >= 0 then
    monitor_states[train_state.no_schedule] = set["tral-no-schedule-timeout"].value * 60 + offset
  end
  if set["tral-manual-timeout"].value >= 0 then
    monitor_states[train_state.manual_control] = set["tral-manual-timeout"].value * 60 + offset
    monitor_states[train_state.manual_control_stop] = set["tral-manual-timeout"].value * 60 + offset
  else
    ok_states[train_state.manual_control] = true
    ok_states[train_state.manual_control_stop] = true
  end
end

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
        alert_time = Queue.insert(data.monitor_queue, alert_time, train_id)
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

if global.proc then
  global.proc = nil
  global.data = {
    monitored_trains = {},
    monitor_queue = {},
    update_queue = {},
    active_alerts = {},
  }
  data = global.data
  global.gui = {}
  global.gui[frame_name] = {}
  global.gui.show_on_alert = {}
  global.gui.active_alert_count = 0
  for pind, player in pairs(game.players) do
     global.gui.show_on_alert[pind] = settings.get_player_settings(game.players[pind])["tral-open-on-alert"].value or nil
  end
  update_timeouts() -- call once for initial setup
  init_train_states()
end




log2("Migration to 0.3.0 successful.")