default = data.raw["gui-style"].default
style_names = defs.names.styles

require("prototypes.sprites")


default[style_names.title_button] = {
  type = "button_style",
  parent = "close_button",
  size = 24,
}


require("prototypes.eui.shared")
require("prototypes.eui.frame")
require("prototypes.sty_alert_window")
require("prototypes.sty_settings_window")