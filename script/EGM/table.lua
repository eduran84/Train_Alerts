local sty = defs.names.gui.table

local EGM_Table = {}

function EGM_Table.build(parent, args)
  local styles = args.styles or {}
  local col_count = args.column_count

  local flow = parent.add{
    type = "flow",
    style = sty.outer_flow,
    direction = "vertical",
  }
  if args.header_elements then
    local header_tbl = flow.add{
      type = "frame",
      style = styles.header_frame or sty.header_frame,
    }.add{
      type = "table",
      column_count = col_count,
      style = styles.table or sty.table
    }
    for i = 1, col_count do
      header_tbl.add(args.header_elements[i])
    end
  end
  local table = flow.add{
    type = "frame",
    style = styles.body_frame or sty.body_frame,
  }.add{
    type = "scroll-pane",
    style = styles.pane or sty.pane,
    vertical_scroll_policy = "auto-and-reserve-space"
  }.add{
    type = "table",
    column_count = col_count,
    style = styles.table or sty.table,
  }
  return table
end

local pairs = pairs
function EGM_Table.add_cells(table, cells)
  if table and table.valid then
    local tbl_add = table.add
    for _, cell in pairs(cells) do
      tbl_add(cell)
    end
  end
end

return EGM_Table