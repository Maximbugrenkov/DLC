-- data.lua

-- 1. Инструмент выделения области
data:extend({
  {
    type = "selection-tool",
    name = "area-creator",
    icon = "__base__/graphics/icons/blueprint.png",
    icon_size = 64,
    flags = {"spawnable"},
    subgroup = "tool",
    order = "a[blueprint]-b[area-creator]",
    stack_size = 1,
    selection_color = {r=0.5, g=0.6, b=0.8, a=0.3},
    alt_selection_color = {r=0.6, g=0.5, b=0.8, a=0.3},
    selection_mode = {"blueprint"},
    alt_selection_mode = {"blueprint"},
    selection_cursor_box_type = "copy",
    alt_selection_cursor_box_type = "copy",
    select = {
      border_color = {r = 0.5, g = 0.6, b = 0.8, a = 0.5},
      cursor_box_type = "copy",
      mode = {"blueprint"}
    },
    alt_select = {
      border_color = {r = 0.5, g = 0.6, b = 0.8, a = 0.5},
      cursor_box_type = "copy",
      mode = {"blueprint"}
    }
  }
})

-- 2. Комбинатор (предмет)
data:extend({
  {
    type = "item",
    name = "drone-logic-controller",
    icon = "__base__/graphics/icons/arithmetic-combinator.png",
    icon_size = 64,
    subgroup = "circuit-network",
    order = "b[combinators]-c[drone-logic-controller]",
    place_result = "drone-logic-controller",
    stack_size = 50
  }
})

-- 3. Комбинатор (сущность)
local combinator = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
combinator.name = "drone-logic-controller"
combinator.icon = "__base__/graphics/icons/arithmetic-combinator.png"
combinator.icon_size = 64
combinator.minable.result = "drone-logic-controller"
data:extend({combinator})

-- 4. Ярлык для инструмента "Создатель области"
data:extend({
  {
    type = "shortcut",
    name = "area-creator-shortcut",
    order = "b[blueprint]-c[area-creator]",
    action = "spawn-item",
    item_to_spawn = "area-creator",
    style = "green",
    icon = "__drone-logic-controller__/graphics/icons/new-blueprint-x56.png",
    icon_size = 56,
    small_icon = "__drone-logic-controller__/graphics/icons/new-blueprint-x56.png",
    small_icon_size = 56
  }
})

-- 5. Ярлык для открытия диспетчера областей
data:extend({
  {
    type = "shortcut",
    name = "area-manager-shortcut",
    order = "b[blueprint]-d[area-manager]",
    action = "lua",
    icon = "__drone-logic-controller__/graphics/icons/new-blueprint-x56.png",
    icon_size = 56,
    style = "green",
    small_icon = "__drone-logic-controller__/graphics/icons/new-blueprint-x56.png",
    small_icon_size = 56
  }
})

-- 6. Горячая клавиша Ctrl+D
data:extend({
  {
    type = "custom-input",
    name = "open-area-manager",
    key_sequence = "CONTROL + D",
    consuming = "none"
  }
})

-- 7. Кастомные спрайты
data:extend({
  {
    type = "sprite",
    name = "my-upgrade-blueprint",
    filename = "__drone-logic-controller__/graphics/icons/new-upgrade-planner-x24.png",
    size = 24,
    flags = {"gui-icon"}
  },
  {
    type = "sprite",
    name = "my-reassign",
    filename = "__drone-logic-controller__/graphics/icons/new-blueprint-x24.png",
    size = 24,
    flags = {"gui-icon"}
  },
  {
    type = "sprite",
    name = "area-creator-icon",
    filename = "__drone-logic-controller__/graphics/icons/new-blueprint-x56.png",
    size = 56,
    flags = {"gui-icon"}
  },
  {
    type = "sprite",
    name = "dlc_blank",
    filename = "__drone-logic-controller__/graphics/icons/blank.png",
    size = 32,
    flags = {"gui-icon"}
  },
  {
    type = "sprite",
    name = "trash-icon-24",
    filename = "__drone-logic-controller__/graphics/icons/trash.png",
    width = 16,
    height = 16,
    x = 32,
    y = 0,
    flags = {"gui-icon"}
  },
  {
    type = "sprite",
    name = "export-icon-24",
    filename = "__drone-logic-controller__/graphics/icons/export.png",
    width = 16,
    height = 16,
    x = 32,
    y = 0,
    flags = {"gui-icon"}
  },
})

-- Спрайты иконок сундуков для использования в GUI (без фона)
data:extend({
  {
    type = "sprite",
    name = "dlc_chest_icon_active_provider",
    filename = "__drone-logic-controller__/graphics/icons/active-provider-chest.png",
    size = 64,
    flags = {"gui-icon"}
  },
  {
    type = "sprite",
    name = "dlc_chest_icon_passive_provider",
    filename = "__drone-logic-controller__/graphics/icons/passive-provider-chest.png",
    size = 64,
    flags = {"gui-icon"}
  },
  {
    type = "sprite",
    name = "dlc_chest_icon_storage",
    filename = "__drone-logic-controller__/graphics/icons/storage-chest.png",
    size = 64,
    flags = {"gui-icon"}
  },
  {
    type = "sprite",
    name = "dlc_chest_icon_buffer",
    filename = "__drone-logic-controller__/graphics/icons/buffer-chest.png",
    size = 64,
    flags = {"gui-icon"}
  },
  {
    type = "sprite",
    name = "dlc_chest_icon_requester",
    filename = "__drone-logic-controller__/graphics/icons/requester-chest.png",
    size = 64,
    flags = {"gui-icon"}
  },
})

-- Новые спрайты для тайлов в правой части редактора
data:extend({
  {
    type = "sprite",
    name = "dlc_cell_blue",
    filename = "__drone-logic-controller__/graphics/icons/blank.png",
    size = 32,
    flags = {"gui-icon"},
    tint = {0.4, 0.6, 0.9, 1}
  },
  {
    type = "sprite",
    name = "dlc_cell_gray",
    filename = "__drone-logic-controller__/graphics/icons/blank.png",
    size = 32,
    flags = {"gui-icon"},
    tint = {0.55, 0.55, 0.55, 1}
  },
})

-- Новые спрайты для клеток с сундуками (синий фон)
data:extend({
  -- Активный провайдер
  {
    type = "sprite",
    name = "dlc_cell_blue_active_provider",
    layers = {
      {
        filename = "__drone-logic-controller__/graphics/icons/blank.png",
        size = 32,
        tint = {0.4, 0.6, 0.9, 1}
      },
      {
        filename = "__drone-logic-controller__/graphics/icons/active-provider-chest.png",
        size = 64,
        scale = 0.35,
        shift = {0, 0}
      }
    }
  },
  -- Пассивный провайдер
  {
    type = "sprite",
    name = "dlc_cell_blue_passive_provider",
    layers = {
      {
        filename = "__drone-logic-controller__/graphics/icons/blank.png",
        size = 32,
        tint = {0.4, 0.6, 0.9, 1}
      },
      {
        filename = "__drone-logic-controller__/graphics/icons/passive-provider-chest.png",
        size = 64,
        scale = 0.35,
        shift = {0, 0}
      }
    }
  },
  -- Складской
  {
    type = "sprite",
    name = "dlc_cell_blue_storage",
    layers = {
      {
        filename = "__drone-logic-controller__/graphics/icons/blank.png",
        size = 32,
        tint = {0.4, 0.6, 0.9, 1}
      },
      {
        filename = "__drone-logic-controller__/graphics/icons/storage-chest.png",
        size = 64,
        scale = 0.35,
        shift = {0, 0}
      }
    }
  },
  -- Буферный
  {
    type = "sprite",
    name = "dlc_cell_blue_buffer",
    layers = {
      {
        filename = "__drone-logic-controller__/graphics/icons/blank.png",
        size = 32,
        tint = {0.4, 0.6, 0.9, 1}
      },
      {
        filename = "__drone-logic-controller__/graphics/icons/buffer-chest.png",
        size = 64,
        scale = 0.35,
        shift = {0, 0}
      }
    }
  },
  -- Реквестор
  {
    type = "sprite",
    name = "dlc_cell_blue_requester",
    layers = {
      {
        filename = "__drone-logic-controller__/graphics/icons/blank.png",
        size = 32,
        tint = {0.4, 0.6, 0.9, 1}
      },
      {
        filename = "__drone-logic-controller__/graphics/icons/requester-chest.png",
        size = 64,
        scale = 0.35,
        shift = {0, 0}
      }
    }
  },
})

-- Новые спрайты для клеток с сундуками (серый фон)
data:extend({
  -- Активный провайдер
  {
    type = "sprite",
    name = "dlc_cell_gray_active_provider",
    layers = {
      {
        filename = "__drone-logic-controller__/graphics/icons/blank.png",
        size = 32,
        tint = {0.55, 0.55, 0.55, 1}
      },
      {
        filename = "__drone-logic-controller__/graphics/icons/active-provider-chest.png",
        size = 64,
        scale = 0.35,
        shift = {0, 0}
      }
    }
  },
  -- Пассивный провайдер
  {
    type = "sprite",
    name = "dlc_cell_gray_passive_provider",
    layers = {
      {
        filename = "__drone-logic-controller__/graphics/icons/blank.png",
        size = 32,
        tint = {0.55, 0.55, 0.55, 1}
      },
      {
        filename = "__drone-logic-controller__/graphics/icons/passive-provider-chest.png",
        size = 64,
        scale = 0.35,
        shift = {0, 0}
      }
    }
  },
  -- Складской
  {
    type = "sprite",
    name = "dlc_cell_gray_storage",
    layers = {
      {
        filename = "__drone-logic-controller__/graphics/icons/blank.png",
        size = 32,
        tint = {0.55, 0.55, 0.55, 1}
      },
      {
        filename = "__drone-logic-controller__/graphics/icons/storage-chest.png",
        size = 64,
        scale = 0.35,
        shift = {0, 0}
      }
    }
  },
  -- Буферный
  {
    type = "sprite",
    name = "dlc_cell_gray_buffer",
    layers = {
      {
        filename = "__drone-logic-controller__/graphics/icons/blank.png",
        size = 32,
        tint = {0.55, 0.55, 0.55, 1}
      },
      {
        filename = "__drone-logic-controller__/graphics/icons/buffer-chest.png",
        size = 64,
        scale = 0.35,
        shift = {0, 0}
      }
    }
  },
  -- Реквестор
  {
    type = "sprite",
    name = "dlc_cell_gray_requester",
    layers = {
      {
        filename = "__drone-logic-controller__/graphics/icons/blank.png",
        size = 32,
        tint = {0.55, 0.55, 0.55, 1}
      },
      {
        filename = "__drone-logic-controller__/graphics/icons/requester-chest.png",
        size = 64,
        scale = 0.35,
        shift = {0, 0}
      }
    }
  },
})

-- 8. Ярлык для выдачи комбинатора Drone Logic Controller (через Lua)
data:extend({
  {
    type = "shortcut",
    name = "dlc-controller-shortcut",
    order = "b[blueprint]-e[dlc-controller]",
    action = "lua",
    icon = "__drone-logic-controller__/graphics/icons/new-blueprint-x56.png",
    icon_size = 56,
    style = "blue",
    small_icon = "__drone-logic-controller__/graphics/icons/new-blueprint-x56.png",
    small_icon_size = 56
  }
})

-- 9. Стиль кнопки клетки
local cell_button_style = {
    type = "button_style",
    parent = "button",
    width = 32,
    height = 32,
    default_background = false,
    draw_background = false,
    left_padding = 0,
    right_padding = 0,
    top_padding = 0,
    bottom_padding = 0,
}
data.raw["gui-style"].default["dlc_cell"] = cell_button_style

-- Стиль для выделенного слота в попапе (зелёный, не меняет размер)
local dlc_slot_selected_style = {
    type = "button_style",
    parent = "slot_button",
    width = 40,
    height = 40,
    default_background_color = {0.3, 0.7, 0.3, 1},
    hovered_background_color = {0.4, 0.8, 0.4, 1},
    clicked_background_color = {0.2, 0.6, 0.2, 1},
}
data.raw["gui-style"].default["dlc_slot_selected"] = dlc_slot_selected_style