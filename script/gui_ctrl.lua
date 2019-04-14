local mod_gui = require("mod-gui")

local frame_name = "tral-frame"
local table_name = "tral_table"
local button_name = "tral_toggle_button"
local WIDTH = {50, 200, 50}

-- helper functions
local pairs, match, tonumber = pairs, string.match, tonumber
local get_main_loco
do
  require("__OpteraLib__.script.train")
  get_main_loco = get_main_locomotive
end
local function select_train(pind, train)
  if train and train.valid and game.players[pind] then
    local loco = get_main_loco(train)
    if loco and loco.valid then
      game.players[pind].opened = loco
    end
  end
end

-- private UI functions
local function get_button(pind)
  local button_flow = mod_gui.get_button_flow(game.players[pind])

  if button_flow[button_name] and button_flow[button_name].valid then
    return button_flow[button_name]
  else
    local button = button_flow.add{type = "sprite-button", style = "mod_gui_button", name = button_name, sprite = "item/locomotive"}
    return button
  end
end

local function get_frame(pind)
  local frame_flow = mod_gui.get_frame_flow(game.players[pind])

  if frame_flow[frame_name] and frame_flow[frame_name].valid then
    return frame_flow[frame_name]
  else
    local frame = frame_flow.add{type = "frame", name = frame_name, caption = {"tral.frame-caption"}, direction = "vertical", style = "tral_transparent_frame"}
    local tbl = frame.add{type = "table", column_count = 3}
    for i = 1, 3 do
      local label = tbl.add{type = "label", style = "ltnt_column_header", caption = {"tral.col-header-"..i}}
      label.style.width = WIDTH[i]
    end
    frame.add{type = "table", name = table_name, column_count = 3}

    frame.visible = false
    return frame
  end
end

local function get_table(pind)
  return get_frame(pind).visible and get_frame(pind)[table_name]
end

-- public functions
local function player_init(pind)
  local button = get_button(pind)
  button.visible =  global.proc.show_button[pind]
end

local function set_alert_state(state, pind)
  if pind then
    local style = state and (not get_frame(pind).visible) and "tral_toggle_button_with_alert" or "mod_gui_button"
    get_button(pind).style = style
  else
    for pind in pairs(game.players) do
      local style = state and (not get_frame(pind).visible) and "tral_toggle_button_with_alert" or "mod_gui_button"
      get_button(pind).style = style
    end
  end
end

local function set_table_entires(entries)
  for pind in pairs(game.players) do
    local tbl = get_table(pind)
    if tbl then
      tbl.clear()
      local counter = 0
      local tbl_add = tbl.add
      for _,arg in pairs(entries) do
        local label = tbl_add(arg)
        label.style.width = WIDTH[(counter % 3)+1]
        counter = counter + 1
      end
    end
  end
end

local function show(pind)
    get_frame(pind).visible = true
end

-- event handlers
local function on_click_handler(event)
  if event.element and event.element.name then
    local name = event.element.name
    local pind = event.player_index
    if name == button_name then
      get_frame(pind).visible = not get_frame(pind).visible
      set_alert_state(false, pind)
    else
      local train_id = tonumber(match(name, "tral_trainbt_(%d+)"))
      if train_id and global.data.monitored_trains[train_id] then
        select_train(pind, global.data.monitored_trains[train_id].train)
        print("Clicked on train", train_id)
      end
    end
  end
end

script.on_event(defines.events.on_gui_click, on_click_handler)

script.on_event("tral-toggle-hotkey",
  function(event)
    local pind = event.player_index
    get_frame(pind).visible = not get_frame(pind).visible
  end
)

return {
  player_init = player_init,
  show = show,
  set_alert_state = set_alert_state,
  set_table_entires = set_table_entires,
  }