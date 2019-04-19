--[[ Copyright (c) 2019 Eduran
 * Part of Train Alerts GUI
 *
 * See LICENSE.md in the project directory for license information.
--]]
local sty = require("script.defines").names.gui.frame
local sty_shared = require("script.defines").names.gui.shared

local methods = {}
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

  new_frame.frame = frame
  new_frame.title_flow = title_flow
  new_frame.body = outer_flow.add{type = "flow", direction = args.direction or "vertical"}
  EUI_Frame.restore_mt(new_frame)
  return new_frame
end

function EUI_Frame.restore_mt(frame_obj)
  setmetatable(frame_obj, EUI_Frame.mt)
end


function methods.add(o, arg_table)
  return o.body.add(arg_table)
end

function methods.add_title_button(o, arg_table)
  return o.title_flow.add(arg_table)
end

function methods.show(o)
  o.frame.visible = true
end
function methods.hide(o)
  o.frame.visible = false
end
function methods.toggle(o)
  o.frame.visible = not o.frame.visible
  return o.frame.visible
end
function methods.is_visible(o)
  return o.frame.visible
end
function methods.is_valid(o)
  return o.body.valid
end


function methods.clear(o)
  o.body.clear()
end
function methods.destroy(o)
  if o.frame.valid then
    o.frame.destroy()
  end
  o = nil
end

function methods.style(o)
  return o.frame.style
end

return EUI_Frame


