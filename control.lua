defs = require("defines")
util = require(defs.pathes.modules.util)

shared = {}

local private_events = {}
function raise_private_event(event, data)
  for _, handler in pairs(private_events[event]) do
    handler(data)
  end
end

local modules = {
  dbg = require("script/debug"),
  selection_tool = require("script/selection_tool"),
  train_state_monitor = require("script/train_state_monitor"),
  alert_window = require("script/gui_alert_window"),
  settings_window = require("script/gui_settings_window"),
}

local function on_settings_changed(event)
  if event.setting and event.setting == defs.names.settings.debug_mode then
    debug_mode = settings.global[defs.names.settings.debug_mode].value
  end
end

local function register_events(modules)
  local all_events = {
    [defines.events.on_runtime_mod_setting_changed] = {on_settings_changed}
  }

  for module_name, module in pairs(modules) do
    if module.get_events and module.get_private_events then
      local module_events = module.get_events()
      for event, handler in pairs(module_events) do
        all_events[event] = all_events[event] or {}
        all_events[event][module_name] = handler
      end
      module_events = module.get_private_events()
      for event, handler in pairs(module_events) do
        private_events[event] = private_events[event] or {}
        private_events[event][module_name] = handler
      end
    else
      error(module_name .. " has no get_events function.")
    end
  end

  for event, handlers in pairs(all_events) do
    if event == defines.events.on_tick then
      error(logger.tostring("Don't use the event handler system for on_tick."))
    end
    local pairs = pairs
    local function action(event)
      for _, handler in pairs(handlers) do
        handler(event)
      end
    end
    script.on_event(event, action)
  end
end

local function on_init()
  debug_mode = settings.global[defs.names.settings.debug_mode].value
  for _, module in pairs(modules) do
    if module.on_init then
      module.on_init()
    end
  end
  register_events(modules)
end
script.on_init(on_init)

local function on_load()
  debug_mode = settings.global[defs.names.settings.debug_mode].value
  for _, module in pairs(modules) do
    if module.on_load then
      module.on_load()
    end
  end
  register_events(modules)
end
script.on_load(on_load)

local function on_configuration_changed(data)
  for _, module in pairs(modules) do
    if module.on_configuration_changed then
      module.on_configuration_changed(data)
    end
  end
end
script.on_configuration_changed(on_configuration_changed)