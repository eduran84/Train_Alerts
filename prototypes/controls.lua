local filtered_entities = {
  "train-stop",
  "rail-signal",
  "rail-chain-signal",
}

data:extend({
  {
    type = "selection-tool",
    name = defs.names.controls.selection_tool,
    stackable = false,
    stack_size = 1,
    icon = defs.pathes.sprites.selection_tool_icon,
    icon_size = 64,
    icon_scale = 0.5,
    selection_color = {r = 0, g = 1, b = 0},
    alt_selection_color = {r = 1, g = 0, b = 0},
    selection_mode = "any-entity",
    alt_selection_mode = "any-entity",
    selection_cursor_box_type = "entity",
    alt_selection_cursor_box_type = "not-allowed",
    flags = {"only-in-cursor"},
    entity_type_filters = filtered_entities,
    alt_entity_type_filters = filtered_entities,
  },
  {
    type = "custom-input",
    name = defs.names.controls.toggle_hotkey,
    key_sequence = "SHIFT + T",
    consuming = "none",
  },
  {
    type = "custom-input",
    name = defs.names.controls.selection_tool_hotkey,
    key_sequence = "CONTROL + SHIFT + T",
    consuming = "none",
  },
  {
    type = "shortcut",
    name = defs.names.controls.toggle_shortcut,
    order = "a[tral-toggle-shortcut]",
    action = "lua",
    localised_name = {"shortcut.tral-toggle"},
    style = "default",
    technology_to_unlock = "railway",
    toggleable = true,
    associated_control_input = defs.names.controls.toggle_hotkey,
    icon =
    {
      filename = defs.pathes.sprites.shortcut_x32,
      priority = "extra-high-no-scale",
      size = 32,
      scale = 1,
      flags = {"icon"}
    },
    disabled_icon =
    {
      filename = defs.pathes.sprites.shortcut_x32_bw,
      priority = "extra-high-no-scale",
      size = 32,
      scale = 1,
      flags = {"icon"}
    },
    small_icon =
    {
      filename = defs.pathes.sprites.shortcut_x24,
      size = 24,
      scale = 1,
      flags = {"icon"}
    },
    disabled_small_icon =
    {
      filename = defs.pathes.sprites.shortcut_x24_bw,
      priority = "extra-high-no-scale",
      size = 24,
      scale = 1,
      flags = {"icon"}
    },
  }
})

if defs.DEVELOPER_MODE then
  data:extend({
    {
      type = "custom-input",
      name = "tral_debug_hotkey",
      key_sequence = "T",
      consuming = "none",
    },
  })
end