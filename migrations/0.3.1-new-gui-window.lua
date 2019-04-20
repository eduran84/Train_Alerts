for k, v in pairs(global.gui[defs.names.gui.elements.main_frame]) do
  if v then
    v:destroy()
  end
end
global.gui[defs.names.gui.elements.main_frame] = {}
-- add additional gui tables introduced in 0.3.1
global.gui[defs.names.gui.elements.setting_frame] = global.gui[defs.names.gui.elements.setting_frame] or {}
global.gui[defs.names.gui.elements.ignore_table] = global.gui[defs.names.gui.elements.ignore_table] or {}