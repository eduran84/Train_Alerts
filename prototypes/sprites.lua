local pathes = defs.pathes.sprites
local names = defs.names.gui.sprites

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
})
