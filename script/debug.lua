logger = require(defs.pathes.modules.logger)
log2 = logger.log
print = logger.print

local data = {}

local class_dict = logger.settings.class_dictionary
class_dict.LuaGuiElement.index = true

local LuaEntity = class_dict.LuaEntity
LuaEntity.position = nil
LuaEntity.unit_number = true

class_dict.LuaItemStack = {
  type = true,
  count = true,
  valid = true,
  valid_for_read = true,
}

local events

if defs.DEVELOPER_MODE then
  debug_mode = true
  logger.add_debug_commands()
  logger.settings.max_depth = 6
  local LuaTrain = class_dict.LuaTrain
  --[[
  LuaTrain.locomotives = true
  LuaTrain.front_rail = true
  LuaTrain.rail_direction_from_front_rail = {
    type = "simple",
    name = "rail_direction_from_front_rail",
    dict = {
      [defines.rail_direction.front]	= "front",
      [defines.rail_direction.back] = "back"
    },
  }
  LuaTrain.back_rail = true
  LuaTrain.rail_direction_from_back_rail = {
    type = "simple",
    name = "rail_direction_from_back_rail",
    dict = {
      [defines.rail_direction.front]	= "front",
      [defines.rail_direction.back] = "back"
    },
  }
  --]]
  LuaTrain.station = true
  LuaTrain.signal = true
  local function log_train(event)
    local player = game.players[event.player_index]
    local selected = player.selected
    local gui = player.gui.left
    if gui.dbg_ui then gui.dbg_ui.destroy() end
    if selected then
      if selected.train then
        print(selected.train)
        local frame = gui.add{type = "frame", name = "dbg_ui"}
        frame.style.height = 500
        local pane_add = frame.add{type = "scroll-pane"}.add
        for line in string.gmatch(logger.tostring(selected.train), "([^\n]*)\n") do
          pane_add{type = "label", caption = line}
        end
      else
        print(selected)
      end

    end
  end
  events =
  {
    --["tral_debug_hotkey"] = log_train,
  }
else
  events = {}
end
local private_events = {}

local dbg = {}

function dbg.on_init()
  global.dbg = global.dbg or data
end

function dbg.on_load()
  data = global.dbg
end

function dbg.get_events()
  return events
end

function dbg.get_private_events()
  return private_events
end

function dbg.on_configuration_changed(data)
end

return dbg