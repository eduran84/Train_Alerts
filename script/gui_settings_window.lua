-- load modules
local EUI_Frame = require("script.eui.EUI_Frame")


--localize functions and variables
local gui
local pairs, log2 = pairs, log2
local names = defs.names
local element_names = names.gui.elements

-- private UI functions
local function get_frame(pind)
  local frame_flow = game.players[pind].gui.center
  local frame_obj = gui[element_names.setting_frame][pind]
  if frame_obj and frame_obj:is_valid() then
    return frame_obj
  else
    if debug_log then
      log2("Creating settings window for player", game.players[pind].name)
    end
    if frame_obj then frame_obj:destroy() end
    frame_obj = EUI_Frame.build{
      parent = frame_flow,
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

    local tbl = frame_obj:add{type = "table", column_count = 3}
    for i = 1, 3 do
      local label = tbl.add{
        type = "label",
        style = "caption_label",
        caption = {"tral.settings-col-header-"..i}
      }
    end
    frame_obj:add{
      type = "scroll-pane",
      vertical_scroll_policy = "auto",
      horizontal_scroll_policy = "never",
      name = element_names.main_pane
    }.add{type = "table", name = element_names.main_table, column_count = 1}
    frame_obj:hide()
    gui[element_names.setting_frame][pind] = frame_obj
    return frame_obj
  end
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
  game.players[event.player_index].opened = frame_obj.frame
end

local function close(event)
  get_frame(event.player_index):hide()
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
}