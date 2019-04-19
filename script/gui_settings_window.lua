-- load modules
local EUI_Frame = require("script.eui.EUI_Frame")
local EUI_Table = require("script.eui.EUI_Table")


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
    local headers = {[1] = {type = "label", style = "caption_label", caption = {"tral.settings-col-header-1"}}}
    local spritelist = {
      [2] = "item/rail-signal",
      [3] = "utility/show_player_names_in_map_view",
      [4] = "item/train-stop",
      [5] = "utility/questionmark",
      [6] = "utility/questionmark",
      }
    for i = 2, 6 do
      headers[i] = {
        type = "sprite-button",
        style = "close_button",
        sprite = spritelist[i],
        enabled = false,
        tooltip = {"tral.settings-col-header-tt-"..i}
      }
    end
    local table_obj = EUI_Table.build{
      parent = frame_obj.body,
      column_count = 6,
      header_elements = headers,
    }
    local cells = {}
    for i = 1, 12 do
      cells[i] = {type = "label", caption = "dummy "..i}
    end

    table_obj:add_cells(cells)


    frame_obj:hide()
    gui[element_names.setting_frame][pind] = frame_obj
    gui[element_names.ignore_table][pind] = table_obj
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