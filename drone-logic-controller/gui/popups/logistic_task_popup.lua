-- gui/popups/logistic_task_popup.lua
local popup_template = require("gui.popup_template")
local task_picker_popup = require("gui.popups.task_picker_popup")

local logistic_task_popup = {}

-- ===== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ (БЕЗ ИЗМЕНЕНИЙ) =====
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

    local edit_btn = create_standard_button(right_flow,
        string.format("chain_edit_name_%d", cid),
        nil, "utility/rename_icon", "tool_button",
        { chain_id = cid, unit_number = unit_number })
    edit_btn.tooltip = "Переименовать цепочку"

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

-- ===== ОСНОВНАЯ ФУНКЦИЯ (ИСПРАВЛЕНА: КРЕСТИК РАБОТАЕТ, ВНУТРЕННИЕ КНОПКИ РАБОТАЮТ) =====
function logistic_task_popup.open(player, unit_number, group_id, area_id, task_id)
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

    local task = nil
    for _, t in ipairs(area.logistic_data.tasks or {}) do
        if t.id == task_id then
            task = t
            break
        end
    end
    if not task then
        player.print("Ошибка: задача не найдена (ID " .. tostring(task_id) .. ").")
        return
    end

    -- Закрыть старый попап для этой же задачи, если он есть
    if not global.active_task_popups then global.active_task_popups = {} end
    local old_popup_name = global.active_task_popups[task_id]
    if old_popup_name then
        local old_frame = player.gui.screen[old_popup_name]
        if old_frame and old_frame.valid then
            if old_frame.tags and old_frame.tags.close_func then
                old_frame.tags.close_func()
            else
                old_frame.destroy()
            end
        end
        global.active_task_popups[task_id] = nil
    end

    -- Инициализация цепочек
    if not task.chains then
        task.chains = {}
    end
    local chains = task.chains
    local next_chain_id = 1
    local next_link_id = 1
    for _, chain in ipairs(chains) do
        if chain.id >= next_chain_id then next_chain_id = chain.id + 1 end
        for _, link in ipairs(chain.links or {}) do
            if link.id >= next_link_id then next_link_id = link.id + 1 end
        end
    end

    -- Список доступных сундуков из глобальной области
    local tasks_list = {}
    if area.global_area_id and global.areas[area.global_area_id] then
        local zone = global.areas[area.global_area_id]
        if zone and zone.tasks then
            for _, task_data in ipairs(zone.tasks) do
                table.insert(tasks_list, {
                    task_id = task_data.task_id,
                    chest_type = task_data.type,
                    custom_name = task_data.custom_name,
                    position = task_data.position
                })
            end
        end
    end
    if #tasks_list == 0 then
        player.print("Нет доступных сундуков в этой области.")
        return
    end

    local function save_chains()
        task.chains = chains
    end

    local function rebuild_ui(content_flow, frame)
        content_flow.clear()

        local scroll_pane = content_flow.add({
            type = "scroll-pane",
            style = "naked_scroll_pane"
        })
        scroll_pane.style.vertically_stretchable = true
        scroll_pane.style.horizontally_stretchable = true

        local main_flow = scroll_pane.add({ type = "flow", direction = "vertical" })
        main_flow.style.width = 440
        main_flow.style.vertically_stretchable = false
        main_flow.style.horizontal_align = "left"

        for idx, chain in ipairs(chains) do
            local chain_frame = create_chain_frame(main_flow, unit_number, chain)
            chain_frame.style.bottom_margin = 4

            local right_aligned = main_flow.add({ type = "flow", direction = "vertical" })
            right_aligned.style.horizontal_align = "right"
            right_aligned.style.width = 420
            right_aligned.style.vertically_stretchable = false
            right_aligned.style.top_margin = 4
            right_aligned.style.bottom_margin = (idx < #chains) and 4 or 0

            for _, link in ipairs(chain.links or {}) do
                local link_frame = create_link_frame(right_aligned, chain.id, link, unit_number, tasks_list)
                link_frame.style.bottom_margin = 4
            end

            local add_link_btn = right_aligned.add({
                type = "button",
                name = string.format("add_link_%d_%d", unit_number, chain.id),
                caption = "+ Добавить звено",
                style = "button",
                tags = { chain_id = chain.id, unit_number = unit_number }
            })
            add_link_btn.style.width = 400
            add_link_btn.style.height = 32
            add_link_btn.style.horizontal_align = "left"
            add_link_btn.style.left_padding = 8
            add_link_btn.style.bottom_margin = 0
        end

        local add_chain_btn = main_flow.add({
            type = "button",
            name = string.format("add_chain_%d", unit_number),
            caption = "+ Добавить цепочку",
            style = "button",
            tags = { unit_number = unit_number }
        })
        add_chain_btn.style.width = 420
        add_chain_btn.style.height = 36
        add_chain_btn.style.horizontal_align = "left"
        add_chain_btn.style.left_padding = 8
        add_chain_btn.style.top_margin = 4
        add_chain_btn.style.bottom_margin = 0
    end

    local title = "Логистическая задача — создание цепочек"
    local frame, content_flow = popup_template.open(player, title, function(cflow, params, frm, pname)
        rebuild_ui(cflow, frm)
    end, nil, 520)

    if frame then
        frame.style.height = 600
        frame.style.minimal_height = 600
    end

    global.active_task_popups[task_id] = frame.name

    -- Локальный обработчик кликов (для внутренних кнопок)
    local function click_handler(event)
        local element = event.element
        if not element or not element.valid then return end

        -- Проверяем, что клик внутри нашего frame
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

        local tags = element.tags
        if not tags then return end

        if element.name == string.format("add_chain_%d", unit_number) then
            local new_chain = {
                id = next_chain_id,
                name = "Новая цепь " .. next_chain_id,
                links = {}
            }
            table.insert(chains, new_chain)
            next_chain_id = next_chain_id + 1
            save_chains()
            rebuild_ui(content_flow, frame)
            return
        end

        if element.name and element.name:find("add_link_") then
            local chain_id = tags.chain_id
            for _, chain in ipairs(chains) do
                if chain.id == chain_id then
                    table.insert(chain.links, { id = next_link_id, from_task_id = nil, to_task_id = nil })
                    next_link_id = next_link_id + 1
                    save_chains()
                    rebuild_ui(content_flow, frame)
                    break
                end
            end
            return
        end

        if element.name and element.name:find("chain_move_up_") then
            local chain_id = tags.chain_id
            for i, c in ipairs(chains) do
                if c.id == chain_id and i > 1 then
                    chains[i], chains[i-1] = chains[i-1], chains[i]
                    save_chains()
                    rebuild_ui(content_flow, frame)
                    break
                end
            end
            return
        end

        if element.name and element.name:find("chain_move_down_") then
            local chain_id = tags.chain_id
            for i, c in ipairs(chains) do
                if c.id == chain_id and i < #chains then
                    chains[i], chains[i+1] = chains[i+1], chains[i]
                    save_chains()
                    rebuild_ui(content_flow, frame)
                    break
                end
            end
            return
        end

        if element.name and element.name:find("chain_delete_") then
            local chain_id = tags.chain_id
            for i, c in ipairs(chains) do
                if c.id == chain_id then
                    table.remove(chains, i)
                    save_chains()
                    rebuild_ui(content_flow, frame)
                    break
                end
            end
            return
        end

        if element.name and element.name:find("link_delete_") then
            local chain_id = tags.chain_id
            local link_id = tags.link_id
            for _, chain in ipairs(chains) do
                if chain.id == chain_id then
                    for i, link in ipairs(chain.links) do
                        if link.id == link_id then
                            table.remove(chain.links, i)
                            save_chains()
                            rebuild_ui(content_flow, frame)
                            return
                        end
                    end
                end
            end
            return
        end

        if element.name and element.name:find("link_from_") then
            local chain_id = tags.chain_id
            local link_id = tags.link_id
            task_picker_popup.open(player, tasks_list, function(selected_task)
                for _, chain in ipairs(chains) do
                    if chain.id == chain_id then
                        for _, link in ipairs(chain.links) do
                            if link.id == link_id then
                                link.from_task_id = selected_task.task_id
                                save_chains()
                                rebuild_ui(content_flow, frame)
                                return
                            end
                        end
                    end
                end
            end, "Выберите сундук-источник")
            return
        end

        if element.name and element.name:find("link_to_") then
            local chain_id = tags.chain_id
            local link_id = tags.link_id
            task_picker_popup.open(player, tasks_list, function(selected_task)
                for _, chain in ipairs(chains) do
                    if chain.id == chain_id then
                        for _, link in ipairs(chain.links) do
                            if link.id == link_id then
                                link.to_task_id = selected_task.task_id
                                save_chains()
                                rebuild_ui(content_flow, frame)
                                return
                            end
                        end
                    end
                end
            end, "Выберите сундук-получатель")
            return
        end

        if element.name and element.name:find("chain_edit_name_") then
            local chain_id = tags.chain_id
            local chain_frame = element.parent.parent
            while chain_frame and not (chain_frame.type == "frame" and chain_frame.tags and chain_frame.tags.chain_id == chain_id) do
                chain_frame = chain_frame.parent
            end
            if chain_frame and chain_frame.tags then
                local label = chain_frame.tags.name_label
                local field = chain_frame.tags.name_field
                if label and field then
                    label.visible = false
                    field.visible = true
                    field.focus()
                    local confirm_handler
                    confirm_handler = function(confirm_event)
                        if confirm_event.element == field then
                            for _, chain in ipairs(chains) do
                                if chain.id == chain_id then
                                    chain.name = field.text
                                    save_chains()
                                    break
                                end
                            end
                            label.caption = field.text
                            label.visible = true
                            field.visible = false
                            script.on_event(defines.events.on_gui_confirmed, nil)
                        end
                    end
                    script.on_event(defines.events.on_gui_confirmed, confirm_handler)
                end
            end
            return
        end
    end

    script.on_event(defines.events.on_gui_click, click_handler)

    -- Единая close_func, которая сохраняет цепочки, удаляет обработчики и закрывает окно
    frame.tags.close_func = function()
        save_chains()
        script.on_event(defines.events.on_gui_click, nil)
        script.on_event(defines.events.on_gui_confirmed, nil)
        if frame and frame.valid then frame.destroy() end
        if global.active_task_popups[task_id] == frame.name then
            global.active_task_popups[task_id] = nil
        end
    end
end

return logistic_task_popup