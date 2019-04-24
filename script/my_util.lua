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

local q = {}
util.queue = q

function q.new()
  return {array = {}, hash = {}}
end

local function find_free_index(array, index, value)
  if array[index] then
    index = find_free_index(array, index + 1, value)
  end
  return index
end

function q.insert(queue, index, value)
 if queue.array[index] then
    index = find_free_index(queue.array, index + 1, value)
  end
  queue.array[index] = value
  queue.hash[value] =  index
  return index
end

function q.pop(queue, index)
  local value = queue.array[index]
  if value ~= nil then
    queue.array[index] = nil
    queue.hash[value] = nil
  end
  return value
end

function q.get_index(queue, value)
  return queue.hash[value]
end

function q.remove_value(queue, value)
  local index = queue.hash[value]
  if index ~= nil then
    queue.array[index] = nil
    queue.hash[value] = nil
  end
  return index
end

return util