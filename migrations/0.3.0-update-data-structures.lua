--[[ Copyright (c) 2019 Eduran
 * Part of Train Alerts GUI
 *
 * See LICENSE.md in the project directory for license information.
--]]

-- Wipe old data and UI
global = {}
local mg = require("mod-gui")
local frame_name = "tral-frame"
for pind, player in pairs(game.players) do
  if mg.get_frame_flow(player)["tral-frame"] and mg.get_frame_flow(player)["tral-frame"].valid then
    mg.get_frame_flow(player)["tral-frame"].destroy()
  end
  if mg.get_button_flow(player)["tral_toggle_button"] and mg.get_button_flow(player)["tral_toggle_button"].valid then
    mg.get_button_flow(player)["tral_toggle_button"].destroy()
  end
end


-- Build new data structure
local defs = require("script.defines")
local ui = require("script.gui_ctrl")

global.data = {
  monitored_trains = {},
  monitor_queue = {},
  update_queue = {},
  active_alerts = {},
}
ui.init()

log2("Migration to 0.3.0 successful.")