local frame_name = "tral-frame"
global.gui = {}
global.gui[frame_name] = {}
global.gui.show_on_alert = {}
global.gui.show_on_alert[1] = true
global.gui.show_button = nil
global.gui.active_alert_count = 0

global.data.alert_queue = {}
global.proc = nil

local mg = require("mod-gui")
mg.get_frame_flow(game.players[1]).clear()
if mg.get_button_flow(game.players[1])["tral_toggle_button"]then
  mg.get_button_flow(game.players[1])["tral_toggle_button"].destroy()
end
