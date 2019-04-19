local Queue = {}

function Queue.insert(queue, index, value)
 if queue[index] then
    index = Queue.find_free_index(queue, index + 1, value)
  end
  queue[index] = value
  log2("queue insert", index, value, queue)
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
  --log2("queue pop", index, value)
  return value
end

return Queue