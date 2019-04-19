--[[ Copyright (c) 2019 Eduran
 * Part of Train Alerts GUI
 *
 * See LICENSE.md in the project directory for license information.
--]]
local Queue = {}

function Queue.insert(queue, index, value)
 if queue[index] then
    index = Queue.find_free_index(queue, index + 1, value)
  end
  queue[index] = value
  return index
end

function Queue.find_free_index(queue, index, value)
  if queue[index] then
    index = Queue.find_free_index(queue, index + 1, value)
  end
  return index
end

function Queue.pop(queue, index)
  local value = queue[index]
  queue[index] = nil
  return value
end

return Queue