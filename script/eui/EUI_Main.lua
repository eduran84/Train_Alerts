local EUI_Table = require("script.eui.EUI_Table")
local EUI_Frame = require("script.eui.EUI_Frame")

local function toggle_key_handler(event)
  local center = game.players[event.player_index].gui.center
  local parent = center.my_frame
  if not parent then
    parent = center.add{type = "flow", name = "my_frame"}
    parent.style.maximal_height = 150
  end
  --[[
  if global.my_table then
    global.my_table:destroy()
    global.my_table = nil
  else
    local cells = {}
    local header = {
      {type = "label", caption = "Train ID", style = "caption_label"},
      {type = "sprite-button", sprite = "item/rail-signal"},
      {type = "sprite-button", sprite = "utility/add"},
    }

    for i = 1,3 do
      cells[i] = {type = "label", caption = "content "..i}
    end
    global.my_table = EUI_Table.build{parent = parent, column_count = 3, header_elements = header}
    global.my_table:add_table_cells(cells)
  end
  --]]
  if global.my_frame then
    global.my_frame:destroy()
    global.my_frame = nil
  else
    global.my_frame = EUI_Frame.build{parent = parent, caption = "Hi there"}
    global.my_frame:add_title_button{type = "sprite-button", style = "close_button", sprite = "utility/close_black"}
    global.my_frame:add{type = "frame"}.style.width = 500
  end
end

return toggle_key_handler