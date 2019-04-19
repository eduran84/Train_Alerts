local path = defs.spritepath
local names = defs.names.gui.sprites

data:extend({
  {
    type = "sprite",
    name = names.questionmark_white,
    filename = path.questionmark_white,
    priority = "high",
    width = 64,
    height = 64,
    scale = 0.5,
  },
  {
    type = "sprite",
    name = names.ignore_white,
    filename = path.ignore_white,
    priority = "high",
    width = 64,
    height = 64,
    scale = 0.5,
  },
})
