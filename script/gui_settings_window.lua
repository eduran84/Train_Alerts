-- load modules
local mod_gui = require("mod-gui")
local EGM_Frame = require(defs.pathes.modules.EGM_Frame)

--localize functions and variables
local pairs, tonumber, floor, log2 = pairs, tonumber, math.floor, log2
local register_ui, unregister_ui = util.register_ui, util.unregister_ui
local raise_private_event = raise_private_event
local styles = defs.names.styles
local names = defs.names
local element_names = names.gui.elements
local offset = defs.constants.timeout_offset
local col2state = {
  -1,
  defines.train_state.wait_signal,
  defines.train_state.wait_station,
  defines.train_state.no_path,
  defines.train_state.manual_control,
  defines.train_state.no_schedule,
}

local tsm
local data = {
  frames = {},
  tables = {},
  table_rows = {},
  ui_elements = {},
}

-- UI functions --

local function build_frame(pind)
  if debug_mode then
    log2("Creating settings window for player", game.players[pind].name)
  end
  local frame = EGM_Frame.build(
    game.players[pind].gui.center,
    {
      name = element_names.setting_frame,
      caption = {"tral.setting-frame-caption"},
      direction = "vertical",
      style = styles.alert_window_frame
    }
  )
  frame.style.maximal_height = defs.constants.setting_frame_max_height
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
  local flow = EGM_Frame.get_flow(frame)  -- content flow of this frame

  flow.add{
    type = "label",
    caption = {"tral.ignore-explainer-1"},
    style = styles.helper_label,
  }
  flow.add{
    type = "label",
    caption = {"tral.ignore-explainer-2"},
    style = styles.helper_label,
  }

  local header_frame = flow.add{
    type = "frame",
    style = styles.table_header_frame,
  }
  local spritelist = {
    [2] = "item/rail-signal",
    [3] = "item/train-stop",
    [4] = names.sprites.no_path,
    [5] = "utility/show_player_names_in_map_view",
    [6] = names.sprites.no_schedule,
  }

  header_frame.add{
    type = "label",
    style = "caption_label",
    caption = {"tral.settings-col-header-1"}
  }.style.width = defs.constants.id_label_width
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
    vertical_scroll_policy = "auto-and-reserve-space",
    horizontal_scroll_policy = "never",
  }
  return frame, table
end

local add_train_to_list  -- defined later
local function reset(pind)
  local frame = data.frames[pind]
  if frame and frame.valid then
    unregister_ui(data.ui_elements, frame)
    frame:destroy()
  end
  data.ui_elements[pind] = nil
  for _, table_row in pairs(data.table_rows) do
    table_row[pind] = nil
  end
  data.frames[pind], data.tables[pind] = build_frame(pind)
  for train_id, train_data in pairs(tsm.ignored_trains) do
    add_train_to_list({train_id = train_id}, pind)
  end
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

do
  local label_def =  {type = "label", style = styles.id_label, caption = ""}
  local textbox_def = {}
  for i = 2, 6 do
    textbox_def[i] = {type = "text-box", style = styles.textbox_valid, text = ""}
  end
  add_train_to_list =  function(event, pind)
    local train_id = event.train_id
    if train_id and (pind or not(tsm.ignored_trains[train_id])) then
      data.table_rows[train_id] = data.table_rows[train_id] or {}

      local label_action = {name = "train_label_clicked", train_id = train_id}
      label_def.caption = train_id

      local timeout_values, players
      if pind then
        players = {[pind] = true}
        timeout_values = tsm.ignored_trains[train_id].timeout_values or shared.train_state_monitor.timeout_values
      else
        players = game.players
        timeout_values = shared.train_state_monitor.timeout_values
      end

      for i = 2, 6 do
        local timeout = timeout_values[col2state[i]]
        textbox_def[i].text = timeout >= 0 and (timeout - offset) / 60 or -1
      end

      local textbox_action = {name = "timeout_text_changed", train_id = train_id}
      for pind in pairs(players) do
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
          --log2("adding box", box, "\ntrain_data:",data.table_rows[train_id])
        end
        register_ui(
          data.ui_elements,
          flow_add{
            type = "sprite-button",
            sprite = "utility/confirm_slot",
            style = "slot_button",
            tooltip = {"tral.settings-apply-tt"},
          },
          {name = "confirm_timeouts", train_id = train_id}
        )
        register_ui(
          data.ui_elements,
          flow_add{
            type = "sprite-button",
            sprite = "utility/set_bar_slot",
            style = "slot_button",
            tooltip = {"tral.settings-reset-tt"},
            },
          {name = "reset_timeouts", train_id = train_id}
        )
      end
      tsm.ignored_trains[train_id] = tsm.ignored_trains[train_id] or {train = tsm.monitored_trains[train_id].train}
    end
    if not pind then open(event.player_index) end
  end
end

local function remove_train_from_list(event, train_id)
  local train = tsm.ignored_trains[train_id].train
  tsm.ignored_trains[train_id] = nil
  if data.table_rows[train_id] then
    for pind in pairs(game.players) do
      local row = data.table_rows[train_id][pind].flow
      unregister_ui(data.ui_elements, row)
      if row and row.valid then row.destroy() end
    end
    data.table_rows[train_id] = nil
    raise_private_event(defs.events.on_timeouts_modified, {train = train})
  end
end

-- event handlers --
local gui_actions = {}
gui_actions.close_window = function(event, action)
  get_frame(event.player_index).visible = false
end
gui_actions.train_label_clicked = function(event, action)
  local train_id = action.train_id
  if event.button == 2 and tsm.ignored_trains[train_id] then --LMB
    util.train.open_train_gui(event.player_index, tsm.ignored_trains[train_id].train)
    local frame = get_frame(event.player_index)
    frame.visible = true
  else
    remove_train_from_list(event, train_id)
  end
end
gui_actions.timeout_text_changed = function(event, action)
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
      box.parent.children[7].enabled = true  -- children[7] is the checkmark button
    end
  elseif not is_valid and was_valid then -- turned invalid
    box.style = styles.textbox_invalid
    player_data.invalid_count = player_data.invalid_count + 1
    box.parent.children[7].enabled = false
    player_data.was_valid[box.index] = is_valid
  end
end
gui_actions.confirm_timeouts = function(event, action)
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
  if debug_mode then log2("New timeouts:", tsm.ignored_trains[train_id].timeout_values) end
  raise_private_event(defs.events.on_timeouts_modified, {train = tsm.ignored_trains[train_id].train})
  for pind, player in pairs(game.players) do
    if pind ~= event.player_index then
      gui_actions.reset_timeouts({player_index = pind, element = event.element}, {train_id = train_id})
      --[[
      data.table_rows[train_id][pind].invalid_count = 0
      for box_id in pairs(data.table_rows[train_id][pind].was_valid) do
        data.table_rows[train_id][pind].was_valid[box_id] = true
      end
      for i = 2, 6 do
        flow.children[i].text = tsm.ignored_trains[train_id].timeout_values[col2state[i]
        flow.children[i].style = styles.textbox_valid
      end   --]]
    end
  end
end

gui_actions.reset_timeouts = function(event, action)
  local timeout_values = tsm.ignored_trains[action.train_id].timeout_values
      or shared.train_state_monitor.timeout_values
  local flow = event.element.parent
  local player_data = data.table_rows[action.train_id][event.player_index]
  for i = 2, 6 do
    local timeout = timeout_values[col2state[i]]
    local box = flow.children[i]
    box.text = timeout >=0 and (timeout - offset) / 60 or -1
    box.style = styles.textbox_valid
    player_data.invalid_count = player_data.invalid_count - 1
    player_data.was_valid[box.index] = true
  end
end

local on_gui_input = function(event)
  local element = event.element
  if not (element and element.valid) then return end
  local player_data = data.ui_elements[event.player_index]
  if not player_data then return end
  local action = player_data[element.index]
  if action then
    if debug_mode then log2("event:", event, "\nplayer data:", player_data, "action:", action) end
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

local function on_player_created(event)
  reset(event.player_index)
end

-- public module API --

local events =
{
  [defines.events.on_gui_click] = on_gui_input,
  [defines.events.on_gui_text_changed] = on_gui_input,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_gui_closed] = on_gui_closed
}

local private_events =
{
  [defs.events.on_train_ignored] = add_train_to_list
}

local gui_settings_window = {}

function gui_settings_window.on_init()
  global.gui_settings_window = global.gui_settings_window or data
  tsm = global.train_state_monitor
  for pind in pairs(game.players) do
    on_player_created({player_index = pind})
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