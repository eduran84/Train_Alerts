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

function util.format_version(version_string)
  if version_string then
    return string.format("%02d.%02d.%02d", string.match(version_string, "(%d+).(%d+).(%d+)"))
  end
end

function util.is_version_below(version, version_to_compare_to)
  version = util.format_version(version)
  if version then
    return version < util.format_version(version_to_compare_to)
  end
  return false
end

return util