global = {}

debug_mode = settings.global[defs.names.settings.debug_mode].value

local queue = util.queue
global.gui_alert_window = {
  viewing_players = {},
  alert_frames = {},
  alert_tables = {},
  show_on_alert = {},
  active_alert_count = 0,
  ui_elements = {}
}

global.train_state_monitor = {
  ltn_stops = {},
  active_alerts = {},
  monitored_trains = {},
  ignored_trains = {},
  update_queue = queue.new(),
  alert_queue = queue.new(),
}

global.gui_settings_window = {
  frames = {},
  tables = {},
  table_rows = {},
  ui_elements = {},
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
    log2("Deleting pre-0.3.0 UI.")
  end
  player.gui.left.clear()
  player.gui.center.clear()
end
