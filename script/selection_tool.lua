local cleanup_interval = 30*60*60 -- 30 minutes
--localize functions and variables
local pairs = pairs
local names = defs.names

-- localize access to relevant global variables
local data = {
  selected_entities = {}
}

-- event handlers --

local rendering = rendering
local function on_player_selected_area(event)
  --[[
  on_player_selected_area

  Called after a player selects an area with a selection-tool item.

  Contains
  player_index :: uint: The player doing the selection.
  area :: BoundingBox: The area selected.
  item :: string: The item used to select the area.
  entities :: array of LuaEntity: The entities selected.
  tiles :: array of LuaTile: The tiles selected.
  --]]
  if event.item == names.controls.selection_tool then
    local draw_sprite = rendering.draw_sprite
    for _, entity in pairs(event.entities) do
      if not data.selected_entities[entity.unit_number] then
        data.selected_entities[entity.unit_number] = {
          draw_sprite{
            sprite = names.sprites.alert_disabled,
            target = entity,
            surface = entity.surface,
            x_scale = 0.5,
            y_scale = 0.5,
            target_offset = {-0.5, -0.5},
          },
          entity
        }
      end
    end
  end
end

local function on_player_alt_selected_area(event)
  if event.item == names.controls.selection_tool then
    local destroy = rendering.destroy
    for _, entity in pairs(event.entities) do
      if data.selected_entities[entity.unit_number] then
        destroy(data.selected_entities[entity.unit_number][1])
        data.selected_entities[entity.unit_number] = nil
      end
    end
  end
end

local function cleanup(event)
  if event.nth_tick ~= cleanup_interval then return end
  for id, entity in pairs(data.selected_entities) do
    if not(entity and entity[2] and entity[2].valid) then
      data.selected_entities[id] = nil
    end
  end
end
script.on_nth_tick(cleanup_interval, cleanup)

-- public module API --

local events =
{
  [defines.events.on_player_selected_area] = on_player_selected_area,
  [defines.events.on_player_alt_selected_area] = on_player_alt_selected_area,
}
local private_events =
{
}

local selection_tool = {}

function selection_tool.on_init()
  global.selection_tool = global.selection_tool or data
end

function selection_tool.on_load()
  data = global.selection_tool
end

function selection_tool.get_events()
  return events
end

function selection_tool.get_private_events()
  return private_events
end

function selection_tool.on_configuration_changed(data)
end

return selection_tool