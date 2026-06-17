-- gui/popups/task_picker_popup.lua
local task_picker_popup = {}

-- Хранилище колбэков, связанных с попапами (не сохраняется в global)
local popup_callbacks = {}

function task_picker_popup.open(player, tasks_list, callback, title)
    title = title or "Выберите сундук"
    local popup_key = "task_picker_" .. tostring(math.random(10000))
    if player.gui.screen[popup_key] then
        player.gui.screen[popup_key].destroy()
        popup_callbacks[popup_key] = nil
    end

    local frame = player.gui.screen.add({
        type = "frame",
        name = popup_key,
        direction = "vertical",
        style = "frame"
    })
    frame.style.width = 400
    frame.style.height = 450
    frame.auto_center = true

    -- Сохраняем колбэк в локальную таблицу
    popup_callbacks[popup_key] = callback

    -- Заголовок
    local title_flow = frame.add({ type = "flow", direction = "horizontal" })
    title_flow.style.height = 32
    title_flow.style.padding = {4,4,4,4}
    title_flow.add({ type = "label", caption = title, style = "frame_title" })
    local spacer = title_flow.add({ type = "empty-widget", style = "draggable_space" })
    spacer.style.horizontally_stretchable = true
    local close_btn = title_flow.add({
        type = "sprite-button", sprite = "utility/close", style = "close_button",
        name = popup_key .. "_close"
    })
    close_btn.style.width = 24
    close_btn.style.height = 24

    -- Вкладки
    local tabs_flow = frame.add({ type = "flow", direction = "horizontal" })
    tabs_flow.style.width = 400
    tabs_flow.style.height = 28
    tabs_flow.style.padding = 4

    local btn_all = tabs_flow.add({
        type = "button", name = popup_key .. "_tab_all", caption = "Все",
        style = "button", tags = { popup_key = popup_key, tab = "all" }
    })
    btn_all.style.horizontally_stretchable = true
    btn_all.style.font_color = {0.9,0.9,0.9}
    btn_all.toggled = true

    local btn_groups = tabs_flow.add({
        type = "button", name = popup_key .. "_tab_groups", caption = "Группы",
        style = "button", tags = { popup_key = popup_key, tab = "groups" }
    })
    btn_groups.style.horizontally_stretchable = true
    btn_groups.style.font_color = {0.7,0.7,0.7}

    local btn_filters = tabs_flow.add({
        type = "button", name = popup_key .. "_tab_filters", caption = "Фильтры",
        style = "button", tags = { popup_key = popup_key, tab = "filters" }
    })
    btn_filters.style.horizontally_stretchable = true
    btn_filters.style.font_color = {0.7,0.7,0.7}

    local scroll = frame.add({ type = "scroll-pane", style = "naked_scroll_pane" })
    scroll.style.vertically_stretchable = true
    local list_container = scroll.add({ type = "flow", direction = "vertical", name = popup_key .. "_list" })
    list_container.style.width = 380
    list_container.style.vertical_spacing = 2

    local function rebuild_list(tasks)
        list_container.clear()
        if not tasks or #tasks == 0 then
            list_container.add({ type = "label", caption = "Нет доступных задач" })
            return
        end
        for _, task in ipairs(tasks) do
            local chest_name = task.custom_name or (task.chest_type or task.type or "Сундук")
            local btn = list_container.add({
                type = "sprite-button",
                name = popup_key .. "_task_" .. task.task_id,
                caption = chest_name,
                style = "list_box_item"
            })
            btn.style.width = 360
            btn.style.height = 32
            btn.style.horizontal_align = "left"
            btn.style.left_padding = 8
            if task.chest_type then
                btn.sprite = "entity/" .. task.chest_type
            end
            btn.tags = { task = task, popup_key = popup_key }
        end
    end

    local function rebuild_groups(tasks)
        list_container.clear()
        local groups = {}
        for _, task in ipairs(tasks) do
            local chest_type = task.chest_type or task.type
            if not groups[chest_type] then groups[chest_type] = {} end
            table.insert(groups[chest_type], task)
        end
        local chest_names = {
            ["active-provider-chest"] = "Активные провайдеры",
            ["passive-provider-chest"] = "Пассивные провайдеры",
            ["storage-chest"] = "Складские сундуки",
            ["buffer-chest"] = "Буферные сундуки",
            ["requester-chest"] = "Реквесторы",
        }
        for chest_type, group_tasks in pairs(groups) do
            local header = list_container.add({ type = "label", caption = chest_names[chest_type] or chest_type, style = "bold_label" })
            header.style.top_margin = 4
            for _, task in ipairs(group_tasks) do
                local chest_name = task.custom_name or (task.chest_type or task.type)
                local btn = list_container.add({
                    type = "sprite-button",
                    name = popup_key .. "_task_" .. task.task_id,
                    caption = "  " .. chest_name,
                    style = "list_box_item"
                })
                btn.style.width = 360
                btn.style.height = 28
                btn.style.horizontal_align = "left"
                btn.style.left_padding = 16
                if task.chest_type then
                    btn.sprite = "entity/" .. task.chest_type
                end
                btn.tags = { task = task, popup_key = popup_key }
            end
        end
        if next(groups) == nil then
            list_container.add({ type = "label", caption = "Нет доступных задач" })
        end
    end

    local function rebuild_filters(tasks)
        list_container.clear()
        for _, task in ipairs(tasks) do
            local chest_name = task.custom_name or (task.chest_type or task.type)
            local flow = list_container.add({ type = "flow", direction = "horizontal" })
            flow.style.width = 360
            flow.add({ type = "checkbox", state = true, caption = chest_name, style = "checkbox" })
        end
        if #tasks == 0 then
            list_container.add({ type = "label", caption = "Нет доступных задач" })
        end
    end

    local function switch_tab(tab_name)
        btn_all.toggled = false
        btn_groups.toggled = false
        btn_filters.toggled = false
        btn_all.style.font_color = {0.7,0.7,0.7}
        btn_groups.style.font_color = {0.7,0.7,0.7}
        btn_filters.style.font_color = {0.7,0.7,0.7}
        if tab_name == "all" then
            btn_all.toggled = true
            btn_all.style.font_color = {0.9,0.9,0.9}
            rebuild_list(tasks_list)
        elseif tab_name == "groups" then
            btn_groups.toggled = true
            btn_groups.style.font_color = {0.9,0.9,0.9}
            rebuild_groups(tasks_list)
        else
            btn_filters.toggled = true
            btn_filters.style.font_color = {0.9,0.9,0.9}
            rebuild_filters(tasks_list)
        end
    end

    switch_tab("all")

    -- Единый обработчик кликов
    local function click_handler(event)
        local element = event.element
        if not element or not element.valid then return end
        
        -- Проверяем, что клик внутри нашего попапа
        local parent = element
        local inside = false
        while parent do
            if parent == frame then
                inside = true
                break
            end
            parent = parent.parent
        end
        if not inside then return end

        -- Переключение вкладок
        if element.tags and element.tags.popup_key == popup_key and element.tags.tab then
            switch_tab(element.tags.tab)
            return
        end

        -- Выбор задачи
        if element.name and element.name:find(popup_key .. "_task_") then
            local task = element.tags and element.tags.task
            local cb = popup_callbacks[popup_key]
            if task and cb then
                cb(task)
            end
            frame.destroy()
            popup_callbacks[popup_key] = nil
            return
        end
        
        -- Закрытие через крестик
        if element.name == popup_key .. "_close" then
            frame.destroy()
            popup_callbacks[popup_key] = nil
            return
        end
    end

    script.on_event(defines.events.on_gui_click, click_handler)

    -- Не сохраняем никаких функций в тегах!
    -- Просто запоминаем ключ в тегах для возможной идентификации (без функций)
    frame.tags = { popup_key = popup_key }
end

return task_picker_popup