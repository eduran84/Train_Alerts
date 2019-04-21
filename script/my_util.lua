local util = require("util")
util.misc = require(defs.pathes.modules.OL_misc)
util.train = require(defs.pathes.modules.OL_train)

local pairs = pairs
local function unregister_ui_private(data, gui_element)
  data[gui_element.index] = nil
  for k, child in pairs (gui_element.children) do
    unregister_ui_private(data, child)
  end
end

function util.unregister_ui(data, gui_element)
  local player_data = data[gui_element.player_index]
  if not player_data then return end
  unregister_ui_private(player_data, gui_element)
end

function util.register_ui(data, gui_element, action)
  local pind = gui_element.player_index
  data[pind] = data[pind] or {}
  data[pind][gui_element.index] = action
end

return util