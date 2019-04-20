--[[ Copyright (c) 2019 Eduran
 * Part of Train Alerts GUI
 *
 * See LICENSE.md in the project directory for license information.
--]]
local sty = defs.names.gui.frame
local sty_shared = defs.names.gui.shared

local methods = require("script.eui.EUI_shared")()
local EUI_Frame = {}
EUI_Frame.mt = {}
EUI_Frame.mt.__index = methods

function EUI_Frame.build(args)
  local new_frame = {}
  local parent = args.parent

  local frame = parent.add{
    type = "frame",
    style = args.style or sty.outer_frame,
    name = args.name,
  }
  local outer_flow = frame.add{type = "flow", direction = "vertical"}
  local title_flow = outer_flow.add{type = "flow", style = sty.title_flow}
  title_flow.add{
    type = "label",
    style = sty.title,
    caption = args.caption,
    tooltip = args.tooltip
  }
  title_flow.add{type = "flow", style = sty_shared.horizontal_spacer}

  new_frame.outer = frame
  new_frame.title_flow = title_flow
  new_frame.container = outer_flow.add{type = "flow", direction = args.direction or "vertical"}
  EUI_Frame.restore_mt(new_frame)
  return new_frame
end

function EUI_Frame.restore_mt(frame_obj)
  setmetatable(frame_obj, EUI_Frame.mt)
end

function methods.add(o, arg_table)
  return o.container.add(arg_table)
end

function methods.add_title_button(o, arg_table)
  return o.title_flow.add(arg_table)
end

function methods.style(o)
  return o.outer.style
end

return EUI_Frame


