-- load modules
local log2 = require("__OpteraLib__.script.logger")()
local mod_gui = require("mod-gui")

-- constants
local frame_name = "tral-frame"
local table_name = "tral_table"
local pane_name = "tral-scroll"
local button_name = "tral_toggle_button"
local WIDTH = {58, 200, 50}

--localize functions
local pairs, match, tonumber = pairs, string.match, tonumber

-- private UI functions
local function get_button(pind)
  local button_flow = mod_gui.get_button_flow(game.players[pind])

  if button_flow[button_name] and button_flow[button_name].valid then
    return button_flow[button_name]
  else
    local button = button_flow.add{type = "sprite-button", style = "mod_gui_button", name = button_name, sprite = "tral_sprite_loco"}
    return button
  end
end

local function get_frame(pind)
  local frame_flow = mod_gui.get_frame_flow(game.players[pind])
  if frame_flow[frame_name] and frame_flow[frame_name].valid then
    return frame_flow[frame_name]
  else
    if debug_log then log2("Rebuilding GUI for player", game.players[pind].name) end
    local frame = frame_flow.add{
      type = "frame",
      name = frame_name,
      caption = {"tral.frame-caption"},
      direction = "vertical",
      style = "tral_transparent_frame"
    }
    frame.style.maximal_height = settings.get_player_settings(game.players[pind])["tral-window-height"].value
    local tbl = frame.add{type = "table", column_count = 3}
    for i = 1, 3 do
      local label = tbl.add{type = "label", style = "caption_label", caption = {"tral.col-header-"..i}}
      label.style.width = WIDTH[i]
    end
    frame.add{
      type = "scroll-pane",
      vertical_scroll_policy = "auto",
      horizontal_scroll_policy = "never",
      name = pane_name
    }.add{type = "table", name = table_name, column_count = 1}
    frame.visible = false
    return frame
  end
end

local function get_table(pind)
  return get_frame(pind).visible and get_frame(pind)[pane_name] and get_frame(pind)[pane_name][table_name]
end

-- for debugging, to simulate UI elements becoming invalid
commands.add_command("reset", "",
  function(event)
    if debug_log then
      local frame = get_frame(event.player_index)
      frame.destroy()
    end
  end
)

-- public functions
local function player_init(pind)
  get_frame(pind).destroy()
  local button = get_button(pind)
  button.visible =  global.proc.show_button[pind]
end

local function set_alert_state(state, pind)
  local style = state and (not get_frame(pind).visible) and "tral_toggle_button_with_alert" or "mod_gui_button"
  get_button(pind).style = style
end

local function set_table_entires(entries)
  for pind in pairs(game.players) do
    local tbl = get_table(pind)
    if tbl then
      tbl.clear()
      local tbl_add = tbl.add
      for _, row in pairs(entries) do
        local elem = tbl_add(row.button)
        elem = elem.add{type = "flow", ignored_by_interaction = true}
        for i = 1,3 do
          elem.add(row.label[i])
        end
      end
    end
  end
end

local function show(pind)
  get_frame(pind).visible = true
end

-- event handlers
do
  local open_train_gui = require("__OpteraLib__.script.train").open_train_gui
  local function on_click_handler(event)
    if event.element and event.element.name then
      if debug_log then log2("on_gui_click event received:", event) end
      local name = event.element.name
      local pind = event.player_index
      if name == button_name then
        get_frame(pind).visible = not get_frame(pind).visible
        set_alert_state(false, pind)
      else
        local train_id = tonumber(match(name, "tral_trainbt_(%d+)"))
        if train_id and global.data.monitored_trains[train_id] then
          open_train_gui(pind, global.data.monitored_trains[train_id].train)
        end
      end
    end
  end
  script.on_event(defines.events.on_gui_click, on_click_handler)
end

script.on_event("tral-toggle-hotkey",
  function(event)
    if debug_log then log2("Toggle hotkey pressed. Event data:", event) end
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
