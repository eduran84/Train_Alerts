--[[ Copyright (c) 2019 Eduran
 * Part of Train Alerts GUI
 *
 * See LICENSE.md in the project directory for license information.
--]]
local shared_methods = {}

function shared_methods.is_valid(o)
  return o.inner.valid
end

function shared_methods.show(o)
  o.outer.visible = true
end

function shared_methods.hide(o)
  o.outer.visible = false
end

function shared_methods.toggle(o)
  o.outer.visible = not o.outer.visible
  return o.outer.visible
end

function shared_methods.is_visible(o)
  return o.outer.visible
end

function shared_methods.is_valid(o)
  return o.container.valid
end

function shared_methods.clear(o)
  o.container.clear()
end

function shared_methods.destroy(o)
  if o.outer.valid then
    o.outer.destroy()
  end
  o = nil
end

return
  function(methods)
    methods = methods or {}
    for name, func in pairs(shared_methods) do
      methods[name] = func
    end
    return methods
  end
