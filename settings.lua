data:extend({
	{
		name = "tral-show-button",
		setting_type = "runtime-per-user",
		type = "bool-setting",
		default_value = true,
    order = "a"
	},
  {
		name = "tral-open-on-alert",
		setting_type = "runtime-per-user",
		type = "bool-setting",
		default_value = true,
    order = "b"
	},

  {
		name = "tral-refresh-interval",
		setting_type = "runtime-global",
		type = "int-setting",
		default_value = 60,
		minimum_value = 20,
		maximum_value = 600,
    order = "a"
	},
	{
		name = "tral-debug-level",
    setting_type = "runtime-global",
		type = "bool-setting",
    default_value = false,
    order = "z"
	},
  {
		name = "tral-station-timeout",
		setting_type = "runtime-global",
		type = "int-setting",
		default_value = 60,
		minimum_value = -1,
		maximum_value = 3600,
    order = "b"
	},
  {
		name = "tral-signal-timeout",
		setting_type = "runtime-global",
		type = "int-setting",
		default_value = 60,
		minimum_value = -1,
		maximum_value = 3600,
    order = "b"
	},
  {
		name = "tral-no-path-timeout",
		setting_type = "runtime-global",
		type = "int-setting",
		default_value = 0,
		minimum_value = -1,
		maximum_value = 3600,
    order = "b"
	},
  {
		name = "tral-no-schedule-timeout",
		setting_type = "runtime-global",
		type = "int-setting",
		default_value = 60,
		minimum_value = -1,
		maximum_value = 3600,
    order = "b"
	},
  {
		name = "tral-manual-timeout",
		setting_type = "runtime-global",
		type = "int-setting",
		default_value = -1,
		minimum_value = -1,
		maximum_value = 3600,
    order = "b"
	},
})