local sty = defs.names.gui.frame
local sty_shared = defs.names.gui.shared

local EGM_Frame = {}
function EGM_Frame.build(parent, args)
  local styles = args.styles or {}

  local frame = parent.add{
    type = "frame",
    style = styles.outer_frame or sty.outer_frame,
    name = args.name,
  }
  local outer_flow = frame.add{type = "flow", direction = "vertical"} --frame.children[1]
  local title_flow = outer_flow.add{type = "flow", style = sty.title_flow}
  title_flow.add{
    type = "label",
    style = styles.title or sty.title,
    caption = args.caption,
    tooltip = args.tooltip
  }
  title_flow.add{type = "flow", style = sty_shared.horizontal_spacer}

  local inner_flow = outer_flow.add{type = "flow", direction = args.direction or "vertical"}
  return frame
end

function EGM_Frame.get_flow(frame)
  if frame and frame.valid then
    return frame.children[1].children[2]
  end
end

function EGM_Frame.add_button(frame, button_args)
  if frame and frame.valid then
    return frame.children[1].children[1].add(button_args)
  end
end

function EGM_Frame.add_element(frame, element_args)
  if frame and frame.valid then
    return frame.children[1].children[2].add(element_args)
  end
end

return EGM_Frame

