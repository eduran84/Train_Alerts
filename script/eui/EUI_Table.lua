local sty = require("script.defines").names.gui.table

local methods = {}
local EUI_Table = {}
EUI_Table.mt = {}
EUI_Table.mt.__index = methods

function EUI_Table.build(args)
  local new_table = {}
  local parent = args.parent
  local n_cols = args.column_count
  new_table.column_count = args.column_count
  local flow = parent.add{type = "flow", style = sty.outer_flow, direction = "vertical"}
  if args.header_elements then
    local frame = flow.add{type = "frame", style = sty.header_frame}
    --frame.style.horizontally_stretchable = true
    local header_tbl = frame.add{type = "table", column_count = n_cols, style = sty.table}
    for i = 1, n_cols do
      header_tbl.add(args.header_elements[i])
    end
  end
  local frame = flow.add{type = "frame", style = sty.body_frame}
  local pane = frame.add{type = "scroll-pane", style = sty.pane}
  new_table.flow = flow
  new_table.body = pane.add{type = "table", column_count = n_cols, style = sty.table}

  setmetatable(new_table, EUI_Table.mt)
  return new_table
end

function methods.add_cells(table_obj, cells)
  for _, cell in pairs(cells) do
    table_obj.body.add(cell)
  end
end

function methods.get_table_cell(table_obj, row, col)
  local N = (row - 1) * table_obj.column_count + col
  return table_obj.body.children[N]
end

function methods.clear(table_obj)
  table_obj.body.clear()
end

function methods.destroy(table_obj)
 table_obj.flow.destroy()
end

return EUI_Table