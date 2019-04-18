-- load modules
local log2 = require("__OpteraLib__.script.logger").log
local mod_gui = require("mod-gui")
local EUI_Frame = require("script.eui.EUI_Frame")
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
  local frame_obj = global.gui[frame_name][pind]
  if frame_obj and frame_obj:is_valid() then
    return frame_obj
  else
    if debug_log then log2("Rebuilding GUI for player", game.players[pind].name) end
    if frame_obj then frame_obj:destroy() end
    frame_obj = EUI_Frame.build{
      parent = frame_flow,
      caption = {"tral.frame-caption"},
      direction = "vertical",
      style = "tral_transparent_frame",
    }
    frame_obj.frame.style.maximal_height = settings.get_player_settings(game.players[pind])["tral-window-height"].value

    local tbl = frame_obj:add{type = "table", column_count = 3}
    for i = 1, 3 do
      local label = tbl.add{type = "label", style = "caption_label", caption = {"tral.col-header-"..i}}
      label.style.width = WIDTH[i]
    end
    frame_obj:add{
      type = "scroll-pane",
      vertical_scroll_policy = "auto",
      horizontal_scroll_policy = "never",
      name = pane_name
    }.add{type = "table", name = table_name, column_count = 1}
    frame_obj:hide()
    global.gui[frame_name][pind] = frame_obj
    return frame_obj
  end
end

local function get_table(pind)
  local frame_obj = get_frame(pind)
  return frame_obj:is_visible() and frame_obj.body[pane_name] and frame_obj.body[pane_name][table_name]
end

-- for debugging, to simulate UI elements becoming invalid
commands.add_command("reset", "",
  function(event)
    game.players[event.player_index].gui.left.clear()
    global.gui[frame_name] = {}
  end
)

-- public functions
local function player_init(pind)
  local player = game.players[pind]
  global.gui.show_on_alert[pind] =  settings.get_player_settings(player)["tral-open-on-alert"].value or nil
  global.gui.show_button[pind] = settings.get_player_settings(player)["tral-show-button"].value
  get_button(pind).visible =  global.gui.show_button[pind]
end

local function init()
  global.gui = {}
  global.gui[frame_name] = {}
  global.gui.show_on_alert = {}
  global.gui.show_button = {}
  for pind, player in pairs(game.players) do
    player_init(pind)
  end
end

local function on_load()
  log2(global.proc, global.gui)
  for pind, frame_obj in pairs(global.gui[frame_name]) do
    EUI_Frame.restore_mt(frame_obj)
  end
end

local function set_alert_state(state, pind)
  local style = state and (not get_frame(pind).frame.visible) and "tral_toggle_button_with_alert" or "mod_gui_button"
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
  get_frame(pind):show()
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
        get_frame(pind):toggle()
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

--local toggle_key_handler = require("script.eui.EUI_Main")
script.on_event("tral-toggle-hotkey",
  function(event)
    if debug_log then log2("Toggle hotkey pressed. Event data:", event) end
    get_frame(event.player_index):toggle()
  end
)

return {
  init = init,
  on_load = on_load,
  player_init = player_init,
  show = show,
  set_alert_state = set_alert_state,
  set_table_entires = set_table_entires,
  }
