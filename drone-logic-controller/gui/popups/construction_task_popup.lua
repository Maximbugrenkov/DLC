-- gui/popups/construction_task_popup.lua
local popup_template = require("gui.popup_template")

local construction_task_popup = {}

function construction_task_popup.open(player, unit_number, group_id, area_id)
    local data = global.combinator_areas[unit_number]
    if not data then return end
    local area = nil
    for _, a in ipairs(data.areas[group_id] or {}) do
        if a.id == area_id then
            area = a
            break
        end
    end
    if not area then return end

    -- Список сундуков из глобальной зоны (для чекбоксов)
    local chests_list = {}
    if area.global_area_id then
        local zone = global.areas[area.global_area_id]
        if zone and zone.tasks then
            for _, task in ipairs(zone.tasks) do
                table.insert(chests_list, {
                    type = task.type,
                    name = task.custom_name or task.type,
                    position = task.position
                })
            end
        end
    end

    -- Тестовые объекты (слоты с иконками и количеством)
    local demo_objects = {
        { name = "assembling-machine-1", count = 1, label = "Сборочный автомат 1" },
        { name = "inserter", count = 2, label = "Манипулятор" },
        { name = "transport-belt", count = 6, label = "Транспортная лента" },
    }
    -- Сортировка по убыванию количества
    table.sort(demo_objects, function(a, b) return a.count > b.count end)

    -- Функция для перестроения таблицы объектов
    local objects_grid = nil
    local function rebuild_objects_table(parent, objects)
        if objects_grid and objects_grid.valid then objects_grid.destroy() end
        local grid = parent.add({ type = "table", column_count = 5 })
        grid.style.horizontal_spacing = 4
        grid.style.vertical_spacing = 2
        grid.style.width = 380
        -- Заголовки
        grid.add({ type = "label", caption = "Объект" })
        grid.add({ type = "label", caption = "Кол-во" })
        grid.add({ type = "label", caption = "↑" })
        grid.add({ type = "label", caption = "↓" })
        grid.add({ type = "label", caption = "Видим" })
        for _, obj in ipairs(objects) do
            -- Слот с иконкой объекта
            local slot = grid.add({
                type = "sprite-button",
                sprite = "entity/" .. obj.name,
                style = "slot_button",
                tooltip = obj.label or obj.name
            })
            slot.style.width = 32
            slot.style.height = 32
            slot.style.padding = 0
            slot.enabled = false   -- просто иконка

            -- Количество (метка)
            grid.add({ type = "label", caption = tostring(obj.count), style = "label" })
            -- Кнопки перемещения (стрелки)
            local up_btn = grid.add({ type = "button", caption = "▲", style = "tool_button", enabled = true })
            local down_btn = grid.add({ type = "button", caption = "▼", style = "tool_button", enabled = true })
            -- Чекбокс видимости
            grid.add({ type = "checkbox", state = true })
        end
        objects_grid = grid
    end

    local title = "Новая строительная задача"
    popup_template.open(player, title, function(content_flow, params, frame, popup_name)
        -- Выбор сундуков-источников (чекбоксы)
        content_flow.add({ type = "label", caption = "Выберите сундуки-источники:", style = "bold_label" })

        local chest_scroll = content_flow.add({ type = "scroll-pane", style = "naked_scroll_pane" })
        chest_scroll.style.height = 120
        chest_scroll.style.width = 380
        local chest_flow = chest_scroll.add({ type = "flow", direction = "vertical" })
        chest_flow.style.width = 360

        if #chests_list == 0 then
            chest_flow.add({ type = "label", caption = "Нет доступных сундуков в этой области" })
        else
            for _, chest in ipairs(chests_list) do
                local cb = chest_flow.add({
                    type = "checkbox",
                    caption = chest.name,
                    state = true,
                    tags = { chest_type = chest.type, chest_name = chest.name }
                })
                cb.style.width = 340
            end
        end

        -- Таблица приоритетов строительства
        content_flow.add({ type = "label", caption = "Приоритет строительства:", style = "bold_label", top_margin = 8 })
        local table_container = content_flow.add({ type = "flow", direction = "vertical", name = "objects_table_container" })
        rebuild_objects_table(table_container, demo_objects)

        -- Кнопка фильтрации (сортировка по убыванию)
        local filter_btn = content_flow.add({
            type = "button",
            caption = "Фильтр: по количеству (убыв.)",
            style = "button",
            enabled = true,
            tags = { unit_number = unit_number, group_id = group_id, area_id = area_id }
        })
        filter_btn.style.width = 380
        frame.tags.filter_callback = function()
            table.sort(demo_objects, function(a, b) return a.count > b.count end)
            rebuild_objects_table(table_container, demo_objects)
        end

        -- Кнопки Создать / Отмена
        local btn_flow = content_flow.add({ type = "flow", direction = "horizontal", top_margin = 16 })
        btn_flow.style.horizontal_align = "center"

        local save_btn = btn_flow.add({
            type = "button",
            caption = "Создать задачу",
            style = "confirm_button",
            tags = {
                unit_number = unit_number,
                group_id = group_id,
                area_id = area_id,
                popup_name = popup_name,
                kind = "construction_task"
            }
        })
        save_btn.style.width = 120

        local cancel_btn = btn_flow.add({
            type = "button",
            caption = "Отмена",
            style = "back_button",
            tags = { popup_name = popup_name }
        })
        cancel_btn.style.width = 80
    end, { unit_number = unit_number, group_id = group_id, area_id = area_id }, 420)
end

return construction_task_popup