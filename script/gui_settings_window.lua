-- load modules
local mod_gui = require("mod-gui")
local EGM_Frame = require(defs.pathes.modules.EGM_Frame)
local styles = defs.names.styles
--localize functions and variables
local pairs, tonumber, floor, log2 = pairs, tonumber, math.floor, log2
local register_ui, unregister_ui = util.register_ui, util.unregister_ui
local raise_private_event = raise_private_event
local names = defs.names
local element_names = names.gui.elements
local offset = defs.constants.timeout_offset

local tsm
local data = {
  viewing_players = {},
  frames = {},
  tables = {},
  table_rows = {},
}

local function build_frame(pind)
  if debug_log then
    log2("Creating settings window for player", game.players[pind].name)
  end
  local frame = EGM_Frame.build(
    game.players[pind].gui.center,
    {
      name = element_names.setting_frame,
      caption = {"tral.setting-frame-caption"},
      direction = "vertical",
    }
  )
  register_ui(
    data.ui_elements,
    EGM_Frame.add_button(frame, {
      type = "sprite-button",
      style = styles.title_button,
      sprite = "utility/close_white",
    }),
    {name = "close_window"}
  )
  frame.visible = false
  local flow = EGM_Frame.get_flow(frame)

  local header_frame = flow.add{
    type = "frame",
    style = styles.table_header_frame,
  }

  local spritelist = {
    [2] = "item/rail-signal",
    [3] = "item/train-stop",
    [4] = "utility/questionmark",
    [5] = "utility/show_player_names_in_map_view",
    [6] = "utility/questionmark",
  }

  header_frame.add {type = "label", style = "caption_label", caption = {"tral.settings-col-header-1"}}.style.width = 100
  header_frame.style.vertical_align = "center"
  for i = 2, 6 do
    local icon = header_frame.add{type = "flow", style = styles.image_flow}.add{
      type = "sprite",
      sprite = spritelist[i],
      tooltip = {"tral.settings-col-header-tt-"..i}
    }
  end

  local table = flow.add{
    type = "frame",
    style = styles.table_body_frame,
  }.add{
    type = "scroll-pane",
    style = styles.table_pane,
    vertical_scroll_policy = "auto-and-reserve-space"
  }
  return frame, table
end

local function reset(pind)
  local frame = data.frames[pind]
  if frame and frame.valid then frame:destroy() end
  data.frames[pind], data.tables[pind] = build_frame(pind)
end

local function get_frame(pind)
  local frame = data.frames[pind]
  if frame and frame.valid then return frame end
  reset(pind)
  return data.frames[pind]
end

local function get_table(pind)
  local table = data.tables[pind]
  if table and table.valid then return table end
  reset(pind)
  return data.tables[pind]
end

local function open(pind)
  local frame = get_frame(pind)
  frame.visible = true
  game.players[pind].opened = frame
end

local col2state = {
  -1,
  defines.train_state.wait_signal,
  defines.train_state.wait_station,
  defines.train_state.no_path,
  defines.train_state.manual_control,
  defines.train_state.no_schedule,
}
local add_train_to_list
do
  local label_def =  {type = "label", style = styles.id_label, caption = ""}
  local textbox_def = {}
  for i = 2, 6 do
    textbox_def[i] = {type = "text-box", style = styles.textbox_valid, text = ""}
  end
  add_train_to_list =  function(event)
    local train_id = event.train_id
    if train_id and not(tsm.ignored_trains[train_id]) then
      tsm.ignored_trains[train_id] = {train = tsm.monitored_trains[train_id].train}
      data.table_rows[train_id] = {}

      local label_action = {name = "train_label_clicked", train_id = train_id}
      label_def.caption = train_id

      local timeout_values = shared.train_state_monitor.timeout_values
      for i = 2, 6 do
        local timeout = timeout_values[col2state[i]]
        textbox_def[i].text = timeout >= 0 and (timeout - offset) / 60 or -1
      end

      local textbox_action = {name = "timeout_text_changed", train_id = train_id}
      for pind in pairs(game.players) do
        local flow = get_table(pind).add{
          type = "flow",
          direction = "horizontal",
          style = styles.table_row_flow
        }
        data.table_rows[train_id][pind] = {flow = flow, invalid_count = 0, was_valid = {}}
        local flow_add = flow.add
        register_ui(data.ui_elements, flow_add(label_def), label_action)
        for _, tb in pairs(textbox_def) do
          local box = flow_add(tb)
          register_ui(data.ui_elements, box, textbox_action)
          data.table_rows[train_id][pind].was_valid[box.index] = true
        end
        register_ui(
          data.ui_elements,
          flow_add{type = "sprite-button", sprite = "utility/confirm_slot", style = "slot_button"},
          {name = "confirm_timeouts", train_id = train_id}
        )
        register_ui(
          data.ui_elements,
          flow_add{type = "sprite-button", sprite = "utility/set_bar_slot", style = "slot_button"},
          {name = "reset_timeouts", train_id = train_id}
        )
      end
    end
    open(event.player_index)
  end
end

local function remove_train_from_list(event, train_id)
  tsm.ignored_trains[train_id] = nil
  if data.table_rows[train_id] then
    for pind in pairs(game.players) do
      local row = data.table_rows[train_id][pind].flow
      unregister_ui(data.ui_elements, row)
      if row and row.valid then row.destroy() end
    end
    data.table_rows[train_id] = nil
  end
end

local gui_actions = {
  close_window = function(event, action)
    get_frame(event.player_index).visible = false
  end,
  train_label_clicked = function(event, action)
    local train_id = action.train_id
    if event.button == 2 and tsm.ignored_trains[train_id] then --LMB
      util.train.open_train_gui(event.player_index, tsm.ignored_trains[train_id].train)
      local frame = get_frame(event.player_index)
      frame.visible = true
    else
      remove_train_from_list(event, train_id)
    end
  end,
  timeout_text_changed = function(event, action)
    local box = event.element
    local num = tonumber(box.text)
    local player_data = data.table_rows[action.train_id][event.player_index]
    local was_valid = player_data.was_valid[box.index]
    local is_valid = num and num == floor(num) and num >= -1

    if is_valid and not was_valid then -- turned valid
      box.style = styles.textbox_valid
      player_data.invalid_count = player_data.invalid_count - 1
      player_data.was_valid[box.index] = is_valid
      if player_data.invalid_count == 0 then
        box.parent.children[7].enabled = true
      end
    elseif not is_valid and was_valid then -- turned invalid
      box.style = styles.textbox_invalid
      player_data.invalid_count = player_data.invalid_count + 1
      box.parent.children[7].enabled = false
      player_data.was_valid[box.index] = is_valid
    end
  end,
  confirm_timeouts = function(event, action)
    local train_id = action.train_id
    local flow = event.element.parent
    tsm.ignored_trains[train_id].timeout_values = {
      [defines.train_state.on_the_path] = -1,
      [defines.train_state.arrive_station] = -1
    }
    for i = 2, 6 do
      local timeout = tonumber(flow.children[i].text)
      if timeout >= 0 then
        timeout = timeout * 60 + offset
      end
      tsm.ignored_trains[train_id].timeout_values[col2state[i]] = timeout
    end
    log2("New timeouts:", tsm.ignored_trains[train_id].timeout_values)
    raise_private_event(defs.events.on_timeouts_modified, {train = tsm.ignored_trains[train_id].train})
  end,

  reset_timeouts = function(event, action)
    local timeout_values = tsm.ignored_trains[action.train_id].timeout_values
        or shared.train_state_monitor.timeout_values
    local flow = event.element.parent
    for i = 2, 6 do
      local timeout = timeout_values[col2state[i]]
      local box = flow.children[i]
      box.text = timeout >=0 and (timeout - 2) / 60 or -1
      box.style = styles.textbox_valid
    end
  end,
}

local on_gui_input = function(event)
  local element = event.element
  if not (element and element.valid) then return end
  local player_data = data.ui_elements[event.player_index]
  if not player_data then return end
  local action = player_data[element.index]
  if action then
    --if debug_mode then log2("event:", event, "\nplayer data:", player_data, "action:", action) end
    gui_actions[action.name](event, action)
    return true
  end
end

local function on_gui_closed(event)
  if event.element and event.element.name == element_names.setting_frame then
    get_frame(event.player_index).visible = false
  elseif event.entity and event.entity.type == "locomotive" then
    local frame = get_frame(event.player_index)
    if frame.visible then
      game.players[event.player_index].opened = frame
    end
  end
end

local events =
{
  [defines.events.on_gui_click] = on_gui_input,
  [defines.events.on_gui_text_changed] = on_gui_input,
  [defines.events.on_player_created] = nil,
  [defines.events.on_gui_closed] = on_gui_closed
}

local private_events =
{
  [defs.events.on_train_ignored] = add_train_to_list
}

-- public module API
local gui_settings_window = {}

function gui_settings_window.on_init()
  global.gui_settings_window = global.gui_settings_window or data
  tsm = global.train_state_monitor
  for pind in pairs(game.players) do
    --on_player_created({player_index = pind})
  end
end

function gui_settings_window.on_load()
  data = global.gui_settings_window
  tsm = global.train_state_monitor
end

function gui_settings_window.get_events()
  return events
end

function gui_settings_window.get_private_events()
  return private_events
end

function gui_settings_window.on_configuration_changed(data)
end

return gui_settings_window