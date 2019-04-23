local names = require("defines").names.settings

data:extend({
  {
		name = names.open_on_alert,
		setting_type = "runtime-per-user",
		type = "bool-setting",
		default_value = true,
    order = "a"
	},
  {
		name = names.window_height,
		setting_type = "runtime-per-user",
		type = "int-setting",
		default_value = 300,
		minimum_value = 200,
		maximum_value = 1500,
    order = "b"
	},

  {
		name = names.refresh_interval,
		setting_type = "runtime-global",
		type = "int-setting",
		default_value = 1,
		minimum_value = 0.9,
		maximum_value = 1,
    order = "a"
	},
	{
		name = names.debug_mode,
    setting_type = "runtime-global",
		type = "bool-setting",
    default_value = false,
    order = "z"
	},
  {
		name = names.timeout_station,
		setting_type = "runtime-global",
		type = "int-setting",
		default_value = 90,
		minimum_value = -1,
		maximum_value = 3600,
    order = "b1"
	},
  {
		name = names.timeout_signal,
		setting_type = "runtime-global",
		type = "int-setting",
		default_value = 90,
		minimum_value = -1,
		maximum_value = 3600,
    order = "b2"
	},
  {
		name = names.timeout_path,
		setting_type = "runtime-global",
		type = "int-setting",
		default_value = 0,
		minimum_value = -1,
		maximum_value = 3600,
    order = "b3"
	},
  {
		name = names.timeout_schedule,
		setting_type = "runtime-global",
		type = "int-setting",
		default_value = 60,
		minimum_value = -1,
		maximum_value = 3600,
    order = "b4"
	},
  {
		name = names.timeout_manual,
		setting_type = "runtime-global",
		type = "int-setting",
		default_value = 60,
		minimum_value = -1,
		maximum_value = 3600,
    order = "b5"
	},
})