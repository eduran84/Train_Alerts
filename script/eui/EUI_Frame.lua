local sty = require("script.defines").names.gui.frame
local sty_shared = require("script.defines").names.gui.shared

local methods = {}
local EUI_Frame = {}
EUI_Frame.mt = {}
EUI_Frame.mt.__index = methods

function EUI_Frame.build(args)
  local new_frame = {}
  local parent = args.parent

  local frame = parent.add{type = "frame", style = sty.outer_frame}
  local outer_flow = frame.add{type = "flow", direction = "vertical"}
  local title_flow = outer_flow.add{type = "flow", style = sty.title_flow}
  title_flow.add{type = "label", style = sty.title, caption = args.caption, tooltip = args.tooltip}
  title_flow.add{type = "flow", style = sty_shared.horizontal_spacer}

  new_frame.frame = frame
  new_frame.title_flow = title_flow
  new_frame.body = outer_flow.add{type = "flow", direction = args.direction or "vertical"}
  setmetatable(new_frame, EUI_Frame.mt)
  return new_frame
end


function methods.add(o, arg_table)
  return o.body.add(arg_table)
end

function methods.add_title_button(o, arg_table)
  return o.title_flow.add(arg_table)
end

function methods.clear(o)
  o.body.clear()
end
function methods.destroy(o)
 o.frame.destroy()
end

function methods.style(o)
  return o.frame.style
end


return EUI_Frame


