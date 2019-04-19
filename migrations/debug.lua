local frame_name = "tral-frame"
global.gui = {}
global.gui[frame_name] = {}
global.gui.show_on_alert = {}
global.gui.show_button = {}
global.gui.active_alert_count = 0

global.data.alert_queue = {}
global.proc = nil


require("mod-gui").get_frame_flow(game.players[1]).clear()