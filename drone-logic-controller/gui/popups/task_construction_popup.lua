-- gui/popups/task_construction_popup.lua
local popup_template = require("gui.popup_template")
local combinator_schedule = require("gui.combinator_schedule")

local task_construction_popup = {}

-- Построение таблицы объектов (10 колонок)
local function build_objects_table(container, task_data, unit_number, group_id, area_id, task_id, player_index)
    container.clear()
    local objects = task_data.construction_objects or {}
    local visible_objects = {}
    for _, obj in ipairs(objects) do
        if obj.visible then
            table.insert(visible_objects, obj)
        end
    end
    if #visible_objects == 0 then
        container.add({ type = "label", caption = "Нет объектов для строительства", style = "label" })
        return
    end

    local columns = 10
    local grid = container.add({ type = "table", column_count = columns })
    grid.style.horizontal_spacing = 2
    grid.style.vertical_spacing = 2
    grid.style.cell_padding = 0

    for idx, obj in ipairs(visible_objects) do
        local btn = grid.add({
            type = "sprite-button",
            name = string.format("const_obj_%d_%d_%d_%d_%d", unit_number, group_id, area_id, task_id, idx),
            sprite = "entity/" .. obj.name,
            style = "slot_button",
            caption = tostring(obj.count),
            tags = {
                unit_number = unit_number,
                group_id = group_id,
                area_id = area_id,
                task_id = task_id,
                obj_index = idx,
                obj_name = obj.name
            }
        })
        btn.style.width = 40
        btn.style.height = 40
        btn.style.font = "default-small-bold"
        btn.style.font_color = {1,1,1}
        btn.style.horizontal_align = "right"
        btn.style.vertical_align = "bottom"
        btn.tooltip = obj.name
    end
end

-- Построение списка фильтров (вертикальный список с чекбоксами)
local function build_filters_list(container, task_data, unit_number, group_id, area_id, task_id, player_index)
    container.clear()
    local objects = task_data.construction_objects or {}
    local unique_types = {}
    for _, obj in ipairs(objects) do
        unique_types[obj.name] = obj.visible
    end
    local sorted_names = {}
    for name, _ in pairs(unique_types) do
        table.insert(sorted_names, name)
    end
    table.sort(sorted_names)
    for _, name in ipairs(sorted_names) do
        local flow = container.add({ type = "flow", direction = "horizontal" })
        flow.style.width = 350
        flow.style.vertical_align = "center"
        flow.style.horizontal_spacing = 8
        local cb = flow.add({
            type = "checkbox",
            name = string.format("filter_cb_%d_%d_%d_%d_%s", unit_number, group_id, area_id, task_id, name),
            caption = name,
            state = unique_types[name],
            tags = {
                unit_number = unit_number,
                group_id = group_id,
                area_id = area_id,
                task_id = task_id,
                obj_name = name
            }
        })
        cb.style.width = 300
    end
    -- Кнопка "Назад"
    local back_btn = container.add({
        type = "button",
        name = "filters_back",
        caption = "← Назад",
        style = "back_button"
    })
    back_btn.style.top_margin = 16
end

function task_construction_popup.open(player, unit_number, group_id, area_id, task_id)
    local data = global.combinator_areas[unit_number]
    if not data then return end
    local area = nil
    for _, a in ipairs(data.areas[group_id] or {}) do
        if a.id == area_id then area = a; break end
    end
    if not area then return end
    local task = nil
    for _, t in ipairs(area.construction_data.tasks or {}) do
        if t.id == task_id then task = t; break end
    end
    if not task then return end
    if not task.construction_objects then
        task.construction_objects = {}
    end

    local title = string.format("Настройка строительной задачи: %s", task.name or "Без имени")

    popup_template.open(player, title, function(content_flow, params, frame, popup_name)
        -- Контейнер для переключения режимов
        local mode_container = content_flow.add({ type = "flow", direction = "vertical", name = "mode_container" })
        mode_container.style.width = 420
        mode_container.style.vertically_stretchable = true

        -- Функция переключения режимов (сохраняется в тегах фрейма)
        local function switch_mode(mode)
            mode_container.clear()
            if mode == "main" then
                -- Кнопка "Настройки" (шестерёнка) – исправлено: вместо неизвестного спрайта используем обычную кнопку с текстом
                local top_flow = mode_container.add({ type = "flow", direction = "horizontal" })
                top_flow.style.width = 420
                top_flow.style.horizontal_align = "right"
                local settings_btn = top_flow.add({
                    type = "button",
                    name = "open_filters",
                    caption = "⚙",
                    style = "tool_button",
                    tags = { unit_number = unit_number, group_id = group_id, area_id = area_id, task_id = task_id }
                })
                settings_btn.style.width = 32
                settings_btn.style.height = 32
                settings_btn.tooltip = "Настройки видимости объектов"

                -- Таблица объектов
                local table_scroll = mode_container.add({ type = "scroll-pane", style = "naked_scroll_pane" })
                table_scroll.style.width = 420
                table_scroll.style.height = 400
                table_scroll.style.vertically_stretchable = true
                local objects_table = table_scroll.add({ type = "flow", direction = "vertical", name = "objects_table" })
                build_objects_table(objects_table, task, unit_number, group_id, area_id, task_id, player.index)
            elseif mode == "filters" then
                local filters_scroll = mode_container.add({ type = "scroll-pane", style = "naked_scroll_pane" })
                filters_scroll.style.width = 420
                filters_scroll.style.height = 400
                filters_scroll.style.vertically_stretchable = true
                local filters_list = filters_scroll.add({ type = "flow", direction = "vertical", name = "filters_list" })
                build_filters_list(filters_list, task, unit_number, group_id, area_id, task_id, player.index)
            end
        end

        frame.tags.switch_mode = switch_mode
        switch_mode("main")
    end, { unit_number = unit_number, group_id = group_id, area_id = area_id, task_id = task_id }, 460)
end

return task_construction_popup