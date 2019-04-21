global = {}


debug_mode = settings.global[defs.names.settings.debug_mode].value

local Queue = require(defs.pathes.modules.queue)
global.gui_alert_window = {
  viewing_players = {},
  alert_frames = {},
  alert_tables = {},
  show_on_alert = {},
  active_alert_count = 0,
}

global.train_state_monitor = {
  ltn_stops = nil,
  active_alerts = {},
  monitored_trains = {},
  ignored_trains = {},
  update_queue = Queue.new(),
  alert_queue = Queue.new(),
}
log2("Resetting global table.")

-- Wipe old UI
local mg = require("mod-gui")
for pind, player in pairs(game.players) do
  if mg.get_frame_flow(player)["tral-frame"] and mg.get_frame_flow(player)["tral-frame"].valid then
    mg.get_frame_flow(player)["tral-frame"].destroy()
  end
  if mg.get_button_flow(player)["tral_toggle_button"] and mg.get_button_flow(player)["tral_toggle_button"].valid then
    mg.get_button_flow(player)["tral_toggle_button"].destroy()
  end
  player.gui.left.clear()
  player.gui.center.clear()
  global.gui_alert_window.show_on_alert[pind] = settings.get_player_settings(player)[defs.names.settings.open_on_alert].value or nil
  log2("Resetting UI.")
end
