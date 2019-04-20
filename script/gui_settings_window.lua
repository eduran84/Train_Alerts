--[[ Copyright (c) 2019 Eduran
 * Part of Train Alerts GUI
 *
 * See LICENSE.md in the project directory for license information.
--]]
-- load modules
local EUI_Frame = require("script.eui.EUI_Frame")
local EUI_Table = require("script.eui.EUI_Table")


--localize functions and variables
local gui
local pairs, log2 = pairs, log2
local names = defs.names
local element_names = names.gui.elements

-- private UI functions
local function build_window(parent, pind)
  if debug_log then
    log2("Creating settings window for player", game.players[pind].name)
  end
  local frame_obj = EUI_Frame.build{
    parent = parent,
    name = element_names.setting_frame,
    caption = {"tral.setting-frame-caption"},
    direction = "vertical",
  }
  --frame_obj.frame.style.maximal_height = settings.get_player_settings(game.players[pind])["tral-window-height"].value
  frame_obj:add_title_button({
    type = "sprite-button",
    style = "tral_title_button",
    sprite = "utility/close_white",
    name = element_names.close_button,
  })
  frame_obj:hide()
  return frame_obj
end
local function build_table(parent, pind)
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
  local table_obj = EUI_Table.build{
    parent = parent,
    column_count = 6,
    header_elements = headers,
  }
  return table_obj
end

local function reset(pind)
  local frame_obj = gui[element_names.setting_frame][pind]
  if frame_obj then frame_obj:destroy() end
  frame_obj = build_window(game.players[pind].gui.center, pind)
  gui[element_names.setting_frame][pind] = frame_obj
  gui[element_names.ignore_table][pind] = build_table(frame_obj.container, pind)
  return frame_obj
end


local function get_frame(pind)
  local frame_obj = gui[element_names.setting_frame][pind]
  if not(frame_obj and frame_obj:is_valid()) then
    frame_obj = reset(pind)
  end
  return frame_obj
end

local function get_table(pind)
  local table_obj = gui[element_names.ignore_table][pind]
  if not(table_obj and table_obj:is_valid()) then
    reset(pind)
  end
  return gui[element_names.ignore_table][pind]
end

-- public functions
local function player_init(pind)
end

local function init()
  gui = global.gui
  global.gui[element_names.setting_frame] = {}
  for pind, player in pairs(game.players) do
    player_init(pind)
  end
end

local function on_load()
  gui = global.gui
  if gui[element_names.setting_frame] then
    for pind, frame_obj in pairs(gui[element_names.setting_frame]) do
      EUI_Frame.restore_mt(frame_obj)
    end
  end
end

local function open(event)
  local frame_obj = get_frame(event.player_index)
  frame_obj:show()
  game.players[event.player_index].opened = frame_obj.outer
end

local function close(event)
  get_frame(event.player_index):hide()
  game.players[event.player_index].opened = nil
end


local add_train_to_list
do
  local cell_def = {[1] = {type = "label", style = "hoverable_bold_label", name = "tral_trainbt_i"}}
  for i = 2, 6 do
    cell_def[i] = {type = "text-box", style = "short_number_textfield"}
  end
  local i2state = {
    defines.train_state.wait_signal,
    defines.train_state.wait_station,
    defines.train_state.no_path,
    defines.train_state.manual_control,
    defines.train_state.no_schedule,
  }

  add_train_to_list =  function(event, train_id, train, monitor_states)
    if not(global.data.ignored_trains[train_id]) then
      cell_def[1].caption = train_id
      cell_def[1].name = "tral_trainbt_i" .. train_id
      global.data.ignored_trains[train_id] = {
        train = train,
        ["ok_states"] = {
          [defines.train_state.wait_signal] = true,
          [defines.train_state.wait_station] = true,
        },
        monitor_states = {},
      }
      for i = 2, 6 do
        cell_def[i].text = (monitor_states[i2state[i]] or 1) - 2
        cell_def[i].name = train_id .. "_" .. i
      end
      for pind in pairs(game.players) do
        get_table(pind):add_cells(cell_def)
      end
    end
    open(event)
  end
end

local function remove_train_from_list(event, train_id)
  global.data.ignored_trains[train_id] = nil
  for pind in pairs(game.players) do
    local tbl = get_table(pind).container
    tbl["tral_trainbt_i" .. train_id].destroy()
    for i = 2, 6 do
      tbl[train_id .. "_" .. i].destroy()
    end
  end
end

script.on_event(defines.events.on_gui_closed,
  function(event)
    if event.element and event.element.name == element_names.setting_frame then
      close(event)
    end
  end
)

return {
  init = init,
  on_load = on_load,
  player_init = player_init,
  open = open,
  close = close,
  add_train_to_list = add_train_to_list,
  remove_train_from_list = remove_train_from_list,
}