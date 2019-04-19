--[[ Copyright (c) 2019 Eduran
 * Part of Train Alerts GUI
 *
 * See LICENSE.md in the project directory for license information.
--]]
local Queue = {}

function Queue.new()
  return {array = {}, hash = {}}
end

local function find_free_index(array, index, value)
  if array[index] then
    index = find_free_index(array, index + 1, value)
  end
  return index
end

function Queue.insert(queue, index, value)
 if queue.array[index] then
    index = find_free_index(queue.array, index + 1, value)
  end
  queue.array[index] = value
  queue.hash[value] =  index
  return index
end

function Queue.pop(queue, index)
  local value = queue.array[index]
  if value ~= nil then
    queue.array[index] = nil
    queue.hash[value] = nil
  end
  return value
end

function Queue.get_index(queue, value)
  return queue.hash[value]
end

function Queue.remove_value(queue, value)
  local index = queue.hash[value]
  if index ~= nil then
    queue.array[index] = nil
    queue.hash[value] = nil
  end
  return index
end

return Queue