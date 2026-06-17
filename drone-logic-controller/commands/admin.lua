-- commands/admin.lua
local area = require("core.area")
local rendering = require("core.rendering")

commands.add_command("dlc-list", "Показывает список всех областей", function(cmd)
    local player = game.players[cmd.player_index]
    if not player then return end

    if not next(global.areas) then
        player.print("Нет созданных областей.")
        return
    end

    for id, zone in pairs(global.areas) do
        player.print(string.format("ID: %d, Имя: %s, Приоритет: %d, Область: (%d,%d)-(%d,%d)",
            id, zone.name, zone.base_priority,
            zone.area.x1, zone.area.y1, zone.area.x2, zone.area.y2))
    end
end)

commands.add_command("dlc-remove", "Удаляет область по ID. Использование: /dlc-remove <id>", function(cmd)
    local player = game.players[cmd.player_index]
    if not player then return end

    local id = tonumber(cmd.parameter)
    if not id then
        player.print("Укажите ID области.")
        return
    end

    if global.areas[id] then
        local name = global.areas[id].name
        rendering.erase_zone(id)
        area.remove(id)
        player.print(string.format("Область '%s' (ID %d) удалена.", name, id))
    else
        player.print(string.format("Область с ID %d не найдена.", id))
    end
end)

commands.add_command("dlc-clear", "Удаляет все области", function(cmd)
    local player = game.players[cmd.player_index]
    if not player then return end

    for id, _ in pairs(global.areas) do
        rendering.erase_zone(id)
    end
    area.clear_all()
    player.print("Все области удалены.")
end)

-- Команда для выдачи комбинатора
commands.add_command("dlc-give", "Выдаёт комбинатор дронов", function(cmd)
    local player = game.players[cmd.player_index]
    if not player then return end
    player.insert{name = "drone-logic-controller", count = 1}
    player.print("Выдан комбинатор дронов.")
end)

-- Команда для просмотра комбинаторов
commands.add_command("dlc-combinators", "Показывает список комбинаторов и их привязки", function(cmd)
    local player = game.players[cmd.player_index]
    if not player then return end

    if not next(global.combinators) then
        player.print("Нет комбинаторов дронов.")
        return
    end

    for unit, data in pairs(global.combinators) do
        local area_info = "не привязан"
        if data.area_id then
            local zone = global.areas[data.area_id]
            area_info = string.format("область '%s' (ID %d)", zone and zone.name or "?", data.area_id)
        end
        local cond = "условие: "
        if data.condition then
            cond = cond .. string.format("%s %s %d", data.condition.signal, data.condition.operator, data.condition.value)
        else
            cond = cond .. "нет"
        end
        player.print(string.format("Комбинатор %d: %s, %s, приоритет true=%d, false=%s",
            unit, area_info, cond, data.true_priority, data.false_priority or "базовый"))
    end
end)

-- Команда привязки комбинатора к области
commands.add_command("dlc-bind", "Привязать комбинатор к области. Использование: /dlc-bind <unit> <area_id>", function(cmd)
    local player = game.players[cmd.player_index]
    if not player then return end

    local args = {}
    for token in string.gmatch(cmd.parameter or "", "%S+") do
        table.insert(args, token)
    end
    if #args < 2 then
        player.print("Использование: /dlc-bind <unit> <area_id>")
        return
    end

    local unit = tonumber(args[1])
    local area_id = tonumber(args[2])
    if not unit or not area_id then
        player.print("Неверные аргументы: unit и area_id должны быть числами.")
        return
    end

    local combinator_data = global.combinators[unit]
    if not combinator_data then
        player.print(string.format("Комбинатор с unit %d не найден.", unit))
        return
    end

    local zone = global.areas[area_id]
    if not zone then
        player.print(string.format("Область с ID %d не найдена.", area_id))
        return
    end

    -- Если комбинатор уже был привязан к другой области, сбрасываем её динамический приоритет
    if combinator_data.area_id then
        area.update_dynamic_priority(combinator_data.area_id, nil)
    end

    -- Устанавливаем новую связь
    combinator_data.area_id = area_id
    -- Задаём стандартное условие, если его нет
    if not combinator_data.condition then
        combinator_data.condition = {signal = "iron-plate", operator = "<", value = 1000}
        combinator_data.true_priority = 300
        combinator_data.false_priority = nil
    end
    combinator_data.last_result = false  -- сбросим, чтобы пересчитать

    player.print(string.format("Комбинатор %d привязан к области '%s' (ID %d).", unit, zone.name, area_id))
end)

-- Команда отвязки комбинатора
commands.add_command("dlc-unbind", "Отвязать комбинатор от области. Использование: /dlc-unbind <unit>", function(cmd)
    local player = game.players[cmd.player_index]
    if not player then return end

    local unit = tonumber(cmd.parameter)
    if not unit then
        player.print("Использование: /dlc-unbind <unit>")
        return
    end

    local combinator_data = global.combinators[unit]
    if not combinator_data then
        player.print(string.format("Комбинатор с unit %d не найден.", unit))
        return
    end

    if combinator_data.area_id then
        area.update_dynamic_priority(combinator_data.area_id, nil)
        combinator_data.area_id = nil
        player.print(string.format("Комбинатор %d отвязан от области.", unit))
    else
        player.print(string.format("Комбинатор %d не был привязан.", unit))
    end
end)

-- добавляем команду
commands.add_command("dlc-test-button", "Открывает тестовую кнопку для проверки переключения цвета", function(cmd)
    local player = game.players[cmd.player_index]
    if player and global.test_button then
        global.test_button.open(player)
    else
        player.print("Тестовый модуль не загружен.")
    end
end)

-- === НОВАЯ КОМАНДА ДЛЯ ОТЛАДКИ ===
commands.add_command("dlc-pending", "Показать содержимое pending_areas для текущего игрока", function(cmd)
    local player = game.players[cmd.player_index]
    if not player then return end

    local pending = global.pending_areas and global.pending_areas[player.index]
    if not pending then
        player.print("Нет активного выделения области (pending_areas пусто).")
        return
    end

    -- Выводим ключевые поля
    player.print("=== PENDING AREA ===")
    player.print(string.format("Размер: %dx%d", pending.width, pending.height))
    player.print(string.format("Координаты: (%d,%d) - (%d,%d)", pending.min_x, pending.min_y, pending.max_x, pending.max_y))
    
    -- Выводим информацию о задачах (пока пусто, но скоро будет)
    player.print(string.format("Задач (tasks): %d", pending.tasks and #pending.tasks or 0))
    player.print(string.format("Групп (groups): %d", pending.groups and #pending.groups or 0))
    player.print(string.format("next_group_id: %s", tostring(pending.next_group_id)))
    player.print("filter_visibility:")
    if pending.filter_visibility then
        for k, v in pairs(pending.filter_visibility) do
            player.print(string.format("  %s = %s", k, tostring(v)))
        end
    else
        player.print("  (отсутствует)")
    end

    -- Для полного дампа используйте serpent, если он есть в окружении
    local serpent_loaded = pcall(require, "serpent")
    if serpent_loaded then
        player.print("\nПолный дамп (serpent):")
        player.print(serpent.block(pending, {comment = false, sparse = true}))
    else
        player.print("\n(serpent не загружен, полный дамп недоступен)")
    end
end)