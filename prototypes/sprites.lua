local pathes = defs.pathes.sprites
local names = defs.names.sprites

data:extend({
  {
    type = "sprite",
    name = names.questionmark_white,
    filename = pathes.questionmark_white,
    priority = "high",
    width = 64,
    height = 64,
    scale = 0.5,
  },
  {
    type = "sprite",
    name = names.ignore_white,
    filename = pathes.ignore_white,
    priority = "high",
    width = 64,
    height = 64,
    scale = 0.5,
  },
  {
    type = "sprite",
    name = names.no_path,
    filename = pathes.no_path_icon,
    priority = "high",
    width = 32,
    height = 32,
    scale = 1,
  },
  {
    type = "sprite",
    name = names.no_schedule,
    filename = pathes.no_schedule_icon,
    priority = "high",
    width = 64,
    height = 64,
    scale = 0.5,
  },
})
