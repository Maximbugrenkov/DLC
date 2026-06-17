-- gui/popups/logistic_link_popup.lua
local popup_template = require("gui.popup_template")
local task_picker_popup = require("gui.popups.task_picker_popup")

local logistic_link_popup = {}

-- ===== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====
local function create_standard_button(parent, name, caption, sprite, style, tags)
    local btn
    if sprite then
        btn = parent.add({
            type = "sprite-button",
            name = name,
            sprite = sprite,
            style = style or "tool_button",
            tags = tags
        })
    else
        btn = parent.add({
            type = "button",
            name = name,
            caption = caption,
            style = style or "tool_button",
            tags = tags
        })
    end
    btn.style.width = 24
    btn.style.height = 24
    return btn
end

local function add_placeholder(parent)
    local ph = parent.add({ type = "empty-widget" })
    ph.style.width = 24
    ph.style.height = 24
    return ph
end

-- Создание фрейма цепочки
local function create_chain_frame(parent, unit_number, chain)
    local cid = chain.id
    local chain_frame = parent.add({ type = "frame", style = "shallow_frame" })
    chain_frame.style.width = 420
    chain_frame.style.height = 36
    chain_frame.style.padding = {2,2,2,2}
    chain_frame.style.margin = {0,0,0,0}
    local row = chain_frame.add({ type = "flow", direction = "horizontal" })
    row.style.vertical_align = "center"
    row.style.horizontal_spacing = 1
    row.style.horizontally_stretchable = true

    local left_flow = row.add({ type = "flow", direction = "horizontal" })
    left_flow.style.horizontal_spacing = 1
    left_flow.style.vertically_stretchable = true

    local name_label = left_flow.add({
        type = "label",
        name = string.format("chain_name_label_%d", cid),
        caption = chain.name,
        style = "bold_label",
        visible = true
    })
    name_label.style.height = 24
    name_label.style.maximal_width = 180
    name_label.style.font = "default-semibold"
    name_label.style.vertical_align = "center"

    local name_field = left_flow.add({
        type = "textfield",
        name = string.format("chain_name_field_%d", cid),
        text = chain.name,
        style = "textbox",
        visible = false
    })
    name_field.style.width = 180
    name_field.style.height = 24
    name_field.tags = { chain_id = cid, unit_number = unit_number }

    local spacer = row.add({ type = "empty-widget", style = "draggable_space" })
    spacer.style.horizontally_stretchable = true

    local right_flow = row.add({ type = "flow", direction = "horizontal" })
    right_flow.style.horizontal_spacing = 1
    right_flow.style.vertical_align = "center"

    -- Кнопка редактирования имени
    local edit_btn = create_standard_button(right_flow,
        string.format("chain_edit_name_%d", cid),
        nil, "utility/rename_icon", "tool_button",
        { chain_id = cid, unit_number = unit_number })
    edit_btn.tooltip = "Переименовать цепочку"

    -- Кнопки перемещения
    local up_btn = create_standard_button(right_flow,
        string.format("chain_move_up_%d", cid),
        "▲", nil, "tool_button",
        { chain_id = cid, unit_number = unit_number })
    up_btn.tooltip = "Вверх"

    local down_btn = create_standard_button(right_flow,
        string.format("chain_move_down_%d", cid),
        "▼", nil, "tool_button",
        { chain_id = cid, unit_number = unit_number })
    down_btn.tooltip = "Вниз"

    -- Кнопка удаления
    local del_btn = create_standard_button(right_flow,
        string.format("chain_delete_%d", cid),
        nil, "utility/trash", "tool_button_red",
        { chain_id = cid, unit_number = unit_number })
    del_btn.tooltip = "Удалить цепочку"

    chain_frame.tags = {
        chain_id = cid,
        unit_number = unit_number,
        edit_btn = edit_btn,
        up_btn = up_btn,
        down_btn = down_btn,
        del_btn = del_btn,
        name_label = name_label,
        name_field = name_field
    }
    return chain_frame
end

-- Создание фрейма звена
local function create_link_frame(parent, chain_id, link, unit_number, tasks_list)
    local link_id = link.id
    local link_frame = parent.add({ type = "frame", style = "inside_shallow_frame" })
    link_frame.style.width = 400
    link_frame.style.height = 36
    link_frame.style.padding = {2,2,2,2}
    link_frame.style.margin = {0,0,0,0}
    local row = link_frame.add({ type = "flow", direction = "horizontal" })
    row.style.vertical_align = "center"
    row.style.horizontal_spacing = 1
    row.style.horizontally_stretchable = true

    local left_flow = row.add({ type = "flow", direction = "horizontal" })
    left_flow.style.horizontal_spacing = 2
    left_flow.style.vertically_stretchable = true

    -- Кнопка "Откуда"
    local from_btn = left_flow.add({
        type = "sprite-button",
        name = string.format("link_from_%d_%d", chain_id, link_id),
        style = "slot_button",
        tags = { chain_id = chain_id, link_id = link_id, slot = "from", unit_number = unit_number }
    })
    from_btn.style.width = 60
    from_btn.style.height = 32
    local from_task = nil
    if link.from_task_id then
        for _, t in ipairs(tasks_list) do
            if t.task_id == link.from_task_id then
                from_task = t
                break
            end
        end
    end
    if from_task then
        from_btn.sprite = "entity/" .. from_task.chest_type
        from_btn.caption = from_task.custom_name or from_task.chest_type
        from_btn.style.font = "default-small"
    else
        from_btn.sprite = "entity/storage-chest"
        from_btn.caption = "Откуда"
    end

    local arrow = left_flow.add({ type = "label", caption = "→", style = "label" })
    arrow.style.width = 20

    -- Кнопка "Куда"
    local to_btn = left_flow.add({
        type = "sprite-button",
        name = string.format("link_to_%d_%d", chain_id, link_id),
        style = "slot_button",
        tags = { chain_id = chain_id, link_id = link_id, slot = "to", unit_number = unit_number }
    })
    to_btn.style.width = 60
    to_btn.style.height = 32
    local to_task = nil
    if link.to_task_id then
        for _, t in ipairs(tasks_list) do
            if t.task_id == link.to_task_id then
                to_task = t
                break
            end
        end
    end
    if to_task then
        to_btn.sprite = "entity/" .. to_task.chest_type
        to_btn.caption = to_task.custom_name or to_task.chest_type
        to_btn.style.font = "default-small"
    else
        to_btn.sprite = "entity/requester-chest"
        to_btn.caption = "Куда"
    end

    local spacer = row.add({ type = "empty-widget", style = "draggable_space" })
    spacer.style.horizontally_stretchable = true

    local right_flow = row.add({ type = "flow", direction = "horizontal" })
    right_flow.style.horizontal_spacing = 1
    right_flow.style.vertical_align = "center"

    add_placeholder(right_flow)
    add_placeholder(right_flow)

    -- Кнопка удаления звена
    local del_btn = create_standard_button(right_flow,
        string.format("link_delete_%d_%d", chain_id, link_id),
        nil, "utility/trash", "tool_button_red",
        { chain_id = chain_id, link_id = link_id, unit_number = unit_number })
    del_btn.tooltip = "Удалить звено"

    link_frame.tags = {
        chain_id = chain_id,
        link_id = link_id,
        unit_number = unit_number,
        from_btn = from_btn,
        to_btn = to_btn,
        del_btn = del_btn
    }
    return link_frame
end

-- ===== ПОСТРОЕНИЕ СПИСКА СУНДУКОВ С УЧЁТОМ ВЫБРАННЫХ ОБЛАСТЕЙ =====
local function build_tasks_list_from_selected_areas(selected_areas)
    local result = {}
    for area_id, enabled in pairs(selected_areas) do
        if enabled then
            local zone = global.areas[area_id]
            if zone and zone.tasks then
                for _, task_data in ipairs(zone.tasks) do
                    table.insert(result, {
                        task_id = task_data.task_id,
                        chest_type = task_data.type,
                        custom_name = task_data.custom_name,
                        position = task_data.position,
                        area_id = area_id,
                        area_name = zone.name
                    })
                end
            end
        end
    end
    return result
end

-- Группировка задач по областям
local function group_tasks_by_area(tasks_list)
    local groups = {}
    for _, task in ipairs(tasks_list) do
        local area_id = task.area_id
        if not groups[area_id] then
            groups[area_id] = {
                area_name = task.area_name,
                tasks = {}
            }
        end
        table.insert(groups[area_id].tasks, task)
    end
    return groups
end

-- ===== ОСНОВНАЯ ФУНКЦИЯ =====
function logistic_link_popup.open(player, unit_number, group_id, area_id, link_id)
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

    -- Находим связь (link)
    local link = nil
    for _, l in ipairs(area.logistic_data.links or {}) do
        if l.id == link_id then
            link = l
            break
        end
    end
    if not link then
        player.print("Ошибка: связь не найдена (ID " .. tostring(link_id) .. ").")
        return
    end

    -- Инициализация цепочек в связи (по аналогии с задачей)
    if not link.chains then
        link.chains = {}
    end
    local chains = link.chains
    local next_chain_id = 1
    local next_link_id = 1
    for _, chain in ipairs(chains) do
        if chain.id >= next_chain_id then next_chain_id = chain.id + 1 end
        for _, lnk in ipairs(chain.links or {}) do
            if lnk.id >= next_link_id then next_link_id = lnk.id + 1 end
        end
    end

    -- Инициализация выбранных областей
    if not link.selected_areas then
        link.selected_areas = {}
        -- По умолчанию выбираем все области, в которых есть сундуки
        for id, zone in pairs(global.areas or {}) do
            if zone.tasks and #zone.tasks > 0 then
                link.selected_areas[id] = true
            end
        end
    end
    local selected_areas = link.selected_areas

    -- Функция сохранения
    local function save_link()
        link.chains = chains
        link.selected_areas = selected_areas
    end

    -- Актуальный список задач (с учётом выбранных областей)
    local function get_current_tasks_list()
        return build_tasks_list_from_selected_areas(selected_areas)
    end

    -- Функция перерисовки UI (вкладки)
    local function rebuild_ui(content_flow, frame, active_tab)
        content_flow.clear()
        active_tab = active_tab or "areas"

        -- Вкладки
        local tabs_flow = content_flow.add({ type = "flow", direction = "horizontal" })
        tabs_flow.style.horizontal_spacing = 0
        tabs_flow.style.bottom_margin = 8

        local btn_areas = tabs_flow.add({
            type = "button", name = "tab_areas", caption = "Области",
            style = "button", tags = { tab = "areas" }
        })
        btn_areas.style.horizontally_stretchable = true
        local btn_all = tabs_flow.add({
            type = "button", name = "tab_all", caption = "Все",
            style = "button", tags = { tab = "all" }
        })
        btn_all.style.horizontally_stretchable = true
        local btn_groups = tabs_flow.add({
            type = "button", name = "tab_groups", caption = "Группы",
            style = "button", tags = { tab = "groups" }
        })
        btn_groups.style.horizontally_stretchable = true
        local btn_filters = tabs_flow.add({
            type = "button", name = "tab_filters", caption = "Фильтры",
            style = "button", tags = { tab = "filters" }
        })
        btn_filters.style.horizontally_stretchable = true

        local function set_active_tab(tab)
            btn_areas.style.font_color = {0.7,0.7,0.7}
            btn_all.style.font_color = {0.7,0.7,0.7}
            btn_groups.style.font_color = {0.7,0.7,0.7}
            btn_filters.style.font_color = {0.7,0.7,0.7}
            if tab == "areas" then
                btn_areas.style.font_color = {0.9,0.9,0.9}
            elseif tab == "all" then
                btn_all.style.font_color = {0.9,0.9,0.9}
            elseif tab == "groups" then
                btn_groups.style.font_color = {0.9,0.9,0.9}
            else
                btn_filters.style.font_color = {0.9,0.9,0.9}
            end
        end

        local tab_content = content_flow.add({ type = "flow", direction = "vertical" })
        tab_content.style.vertically_stretchable = true

        -- Панель "Области"
        local areas_panel = tab_content.add({ type = "flow", direction = "vertical", name = "areas_panel" })
        areas_panel.style.vertically_stretchable = true
        local scroll_areas = areas_panel.add({ type = "scroll-pane", style = "naked_scroll_pane" })
        scroll_areas.style.vertically_stretchable = true
        local areas_list_flow = scroll_areas.add({ type = "flow", direction = "vertical" })
        areas_list_flow.style.width = 400
        for id, zone in pairs(global.areas or {}) do
            local cb = areas_list_flow.add({
                type = "checkbox",
                name = "area_select_" .. id,
                caption = zone.name,
                state = selected_areas[id] == true,
                tags = { area_id = id }
            })
            cb.style.width = 380
        end

        -- Панель "Все" (с группировкой по областям)
        local all_panel = tab_content.add({ type = "flow", direction = "vertical", name = "all_panel", visible = false })
        all_panel.style.vertically_stretchable = true
        local scroll_all = all_panel.add({ type = "scroll-pane", style = "naked_scroll_pane" })
        scroll_all.style.vertically_stretchable = true
        local all_list_flow = scroll_all.add({ type = "flow", direction = "vertical" })
        all_list_flow.style.width = 400

        -- Панель "Группы"
        local groups_panel = tab_content.add({ type = "flow", direction = "vertical", name = "groups_panel", visible = false })
        groups_panel.style.vertically_stretchable = true
        local scroll_groups = groups_panel.add({ type = "scroll-pane", style = "naked_scroll_pane" })
        scroll_groups.style.vertically_stretchable = true
        local groups_list_flow = scroll_groups.add({ type = "flow", direction = "vertical" })
        groups_list_flow.style.width = 400

        -- Панель "Фильтры"
        local filters_panel = tab_content.add({ type = "flow", direction = "vertical", name = "filters_panel", visible = false })
        filters_panel.style.vertically_stretchable = true
        local scroll_filters = filters_panel.add({ type = "scroll-pane", style = "naked_scroll_pane" })
        scroll_filters.style.vertically_stretchable = true
        local filters_list_flow = scroll_filters.add({ type = "flow", direction = "vertical" })
        filters_list_flow.style.width = 400

        local function refresh_all_panel()
            all_list_flow.clear()
            local tasks = get_current_tasks_list()
            local grouped = group_tasks_by_area(tasks)
            for area_id, group in pairs(grouped) do
                all_list_flow.add({ type = "label", caption = group.area_name, style = "bold_label" })
                for _, task in ipairs(group.tasks) do
                    local chest_name = task.custom_name or task.chest_type
                    local btn = all_list_flow.add({
                        type = "sprite-button",
                        name = "select_task_" .. task.task_id,
                        caption = chest_name,
                        style = "list_box_item",
                        sprite = "entity/" .. task.chest_type,
                        tags = { task = task }
                    })
                    btn.style.width = 380
                    btn.style.height = 32
                    btn.style.horizontal_align = "left"
                    btn.style.left_padding = 8
                end
            end
            if next(grouped) == nil then
                all_list_flow.add({ type = "label", caption = "Нет доступных сундуков в выбранных областях" })
            end
        end

        local function refresh_groups_panel()
            groups_list_flow.clear()
            local tasks = get_current_tasks_list()
            -- Группировка по типу сундука, затем по областям
            local chest_groups = {}
            for _, task in ipairs(tasks) do
                local ct = task.chest_type
                if not chest_groups[ct] then chest_groups[ct] = {} end
                table.insert(chest_groups[ct], task)
            end
            local chest_names = {
                ["active-provider-chest"] = "Активные провайдеры",
                ["passive-provider-chest"] = "Пассивные провайдеры",
                ["storage-chest"] = "Складские сундуки",
                ["buffer-chest"] = "Буферные сундуки",
                ["requester-chest"] = "Реквесторы",
            }
            for chest_type, chest_tasks in pairs(chest_groups) do
                groups_list_flow.add({ type = "label", caption = chest_names[chest_type] or chest_type, style = "bold_label" })
                local grouped_by_area = group_tasks_by_area(chest_tasks)
                for area_id, group in pairs(grouped_by_area) do
                    groups_list_flow.add({ type = "label", caption = "  " .. group.area_name, style = "label" })
                    for _, task in ipairs(group.tasks) do
                        local chest_name = task.custom_name or task.chest_type
                        local btn = groups_list_flow.add({
                            type = "sprite-button",
                            name = "select_task_" .. task.task_id,
                            caption = "    " .. chest_name,
                            style = "list_box_item",
                            sprite = "entity/" .. task.chest_type,
                            tags = { task = task }
                        })
                        btn.style.width = 360
                        btn.style.height = 28
                        btn.style.horizontal_align = "left"
                        btn.style.left_padding = 16
                    end
                end
            end
            if next(chest_groups) == nil then
                groups_list_flow.add({ type = "label", caption = "Нет доступных сундуков в выбранных областях" })
            end
        end

        local function refresh_filters_panel()
            filters_list_flow.clear()
            local tasks = get_current_tasks_list()
            for _, task in ipairs(tasks) do
                local chest_name = task.custom_name or task.chest_type
                local flow = filters_list_flow.add({ type = "flow", direction = "horizontal" })
                flow.style.width = 380
                flow.add({ type = "checkbox", state = true, caption = chest_name, style = "checkbox" })
            end
            if #tasks == 0 then
                filters_list_flow.add({ type = "label", caption = "Нет доступных сундуков в выбранных областях" })
            end
        end

        -- Обработка выбора сундука из любой панели
        local function on_task_selected(selected_task)
            -- Здесь нужно добавить звено в текущую цепочку?
            -- В данном попапе мы настраиваем связи, поэтому выбор сундука должен идти в звено (from/to)
            -- Этот функционал будет реализован в кликах по кнопкам "Откуда"/"Куда" в звеньях.
            -- Пока просто заглушка.
            player.print("Выбран сундук: " .. (selected_task.custom_name or selected_task.chest_type))
        end

        -- Заполнение панелей
        refresh_all_panel()
        refresh_groups_panel()
        refresh_filters_panel()

        -- Обработчики кликов по кнопкам выбора сундука
        local function click_handler(event)
            local element = event.element
            if not element or not element.valid then return end
            local parent = element
            while parent and parent ~= frame do parent = parent.parent end
            if parent ~= frame then return end

            if element.name and element.name:find("select_task_") then
                local task = element.tags and element.tags.task
                if task then
                    on_task_selected(task)
                end
                return
            end
            if element.name and element.name:find("area_select_") then
                local area_id = element.tags.area_id
                selected_areas[area_id] = element.state
                save_link()
                refresh_all_panel()
                refresh_groups_panel()
                refresh_filters_panel()
                return
            end
            if element.name and element.name:find("^tab_") then
                local tab = element.tags.tab
                areas_panel.visible = (tab == "areas")
                all_panel.visible = (tab == "all")
                groups_panel.visible = (tab == "groups")
                filters_panel.visible = (tab == "filters")
                set_active_tab(tab)
                return
            end
            -- Обработка цепочек и звеньев (скопировано из logistic_task_popup)
            -- ... (здесь будет код для управления цепочками)
        end
        script.on_event(defines.events.on_gui_click, click_handler)

        -- Устанавливаем активную вкладку
        areas_panel.visible = (active_tab == "areas")
        all_panel.visible = (active_tab == "all")
        groups_panel.visible = (active_tab == "groups")
        filters_panel.visible = (active_tab == "filters")
        set_active_tab(active_tab)
    end

    -- Открываем попап
    local title = "Логистическая связь — создание цепочек"
    local frame, content_flow = popup_template.open(player, title, function(cflow, params, frm, pname)
        rebuild_ui(cflow, frm, "areas")
    end, nil, 520)

    if frame then
        frame.style.height = 600
        frame.style.minimal_height = 600
    end

    frame.tags.close_func = function()
        save_link()
        frame.destroy()
    end
end

return logistic_link_popup