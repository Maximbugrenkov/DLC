-- utils/gui_helpers.lua
-- Вспомогательные функции, используемые обработчиками GUI

local gui_helpers = {}

function gui_helpers.clear_task_status_frames(player_index)
    if not global.task_status_frames then return end
    for task_id, frame in pairs(global.task_status_frames) do
        if frame.valid and frame.tags and frame.tags.player_index == player_index then
            frame.destroy()
            global.task_status_frames[task_id] = nil
        end
    end
end

function gui_helpers.find_task_by_id(tasks, task_id)
    for _, task in ipairs(tasks) do
        if task.task_id == task_id then return task end
    end
    return nil
end

function gui_helpers.find_entity_by_task(task)
    if not task or not task.position or not task.chest_type then return nil end
    local surface = game.surfaces[1]
    local entities = surface.find_entities_filtered{
        name = task.chest_type,
        position = task.position,
        limit = 1
    }
    return entities[1]
end

-- Вспомогательная функция для окна добавления задач в группу (область редактора)
function gui_helpers.rebuild_group_add_task_window(frame, pending, group_id, player_index)
    if not frame or not frame.valid then return end
    local tab_scroll = frame.group_add_tab_scroll
    if not tab_scroll then return end
    local tab_content = tab_scroll.group_add_tab_content
    if not tab_content then return end
    local tab_all = tab_content.tab_all
    local tab_filters = tab_content.tab_filters
    if not tab_all or not tab_filters then return end

    tab_all.clear()
    tab_filters.clear()

    local CHEST_NAMES_ALL = {
        ["active-provider-chest"] = "Активный провайдер",
        ["passive-provider-chest"] = "Пассивный провайдер",
        ["storage-chest"] = "Складской сундук",
        ["buffer-chest"] = "Буферный сундук",
        ["requester-chest"] = "Реквестор",
    }

    local grid_states = pending.grid_states
    local active_tasks = {}
    for _, task in ipairs(pending.tasks) do
        local row, col = task.grid_row, task.grid_col
        if row and col and grid_states[row] and grid_states[row][col] then
            if task.group_id ~= group_id then
                table.insert(active_tasks, task)
            end
        end
    end

    table.sort(active_tasks, function(a,b) return a.display_order < b.display_order end)
    if #active_tasks == 0 then
        tab_all.add{type="label", caption="Нет доступных задач", style="label"}
    else
        for _, task in ipairs(active_tasks) do
            local chest_name = CHEST_NAMES_ALL[task.chest_type] or task.chest_type
            local display_name = task.custom_name or chest_name
            local btn = tab_all.add{
                type = "sprite-button",
                name = "group_add_task_item_" .. task.task_id,
                caption = display_name,
                tags = { group_id = group_id, task_id = task.task_id, player_index = player_index }
            }
            btn.style.width = 320
            btn.style.height = 32
            btn.style.font = "default-semibold"
            btn.style.font_color = {1, 1, 1}
            btn.style.horizontal_align = "left"
            btn.style.left_padding = 4
            if task.chest_type then
                btn.sprite = "entity/" .. task.chest_type
            end
        end
    end

    local CHEST_GROUPS = {
        ["active-provider-chest"] = "Активные провайдеры",
        ["passive-provider-chest"] = "Пассивные провайдеры",
        ["storage-chest"] = "Складские сундуки",
        ["buffer-chest"] = "Буферные сундуки",
        ["requester-chest"] = "Реквесторы",
    }

    local has_any = false
    for _, chest_type in ipairs({"active-provider-chest", "passive-provider-chest", "storage-chest", "buffer-chest", "requester-chest"}) do
        local tasks_of_type = {}
        for _, task in ipairs(active_tasks) do
            if task.chest_type == chest_type then
                table.insert(tasks_of_type, task)
            end
        end
        if #tasks_of_type > 0 then
            has_any = true
            local header_frame = tab_filters.add{
                type = "frame",
                style = "bordered_frame"
            }
            header_frame.style.width = 340
            header_frame.style.padding = 6
            header_frame.style.margin = {0, 0, 4, 0}
            header_frame.add{
                type = "label",
                caption = CHEST_GROUPS[chest_type] or chest_type,
                style = "bold_label",
                font_color = {1, 1, 1}
            }
            local tasks_flow = tab_filters.add{
                type = "flow",
                direction = "vertical"
            }
            tasks_flow.style.width = 340
            tasks_flow.style.vertical_spacing = 2
            tasks_flow.style.padding = {0, 0, 0, 0}
            tasks_flow.style.margin = {0, 0, 8, 0}
            table.sort(tasks_of_type, function(a,b) return a.display_order < b.display_order end)
            for _, task in ipairs(tasks_of_type) do
                local chest_name = CHEST_NAMES_ALL[task.chest_type] or task.chest_type
                local display_name = task.custom_name or chest_name
                local btn = tasks_flow.add{
                    type = "sprite-button",
                    name = "group_add_task_item_" .. task.task_id,
                    caption = display_name,
                    tags = { group_id = group_id, task_id = task.task_id, player_index = player_index }
                }
                btn.style.width = 320
                btn.style.height = 32
                btn.style.font = "default-semibold"
                btn.style.font_color = {1, 1, 1}
                btn.style.horizontal_align = "left"
                btn.style.left_padding = 4
                if task.chest_type then
                    btn.sprite = "entity/" .. task.chest_type
                end
            end
        end
    end
    if not has_any then
        tab_filters.add{type="label", caption="Нет доступных задач", style="label"}
    end
end

-- Новая функция: завершить текущее редактирование имени (задача/группа/область)
function gui_helpers.finish_current_edit(player_index)
    if not global.active_edit_element then global.active_edit_element = {} end
    local edit = global.active_edit_element[player_index]
    if not edit then return end

    if edit.type == "task" then
        local label = global.task_name_labels and global.task_name_labels[edit.id]
        local field = global.task_name_textfields and global.task_name_textfields[edit.id]
        local pending = global.pending_areas[player_index]
        local task = pending and gui_helpers.find_task_by_id(pending.tasks, edit.id)
        if label and field and task then
            local new_name = field.text
            if new_name and new_name ~= "" then
                task.custom_name = new_name
                label.caption = new_name
            else
                task.custom_name = nil
                local entity = gui_helpers.find_entity_by_task(task)
                label.caption = (entity and entity.valid) and entity.localised_name or task.chest_type
            end
            field.visible = false
            label.visible = true
        end
    elseif edit.type == "group" then
        local label = global.group_name_labels and global.group_name_labels[edit.id]
        local field = global.group_name_textfields and global.group_name_textfields[edit.id]
        local pending = global.pending_areas[player_index]
        if label and field and pending then
            local new_name = field.text
            for _, group in ipairs(pending.groups) do
                if group.id == edit.id then
                    group.name = (new_name ~= "" and new_name) or "Новая группа"
                    label.caption = group.name
                    break
                end
            end
            field.visible = false
            label.visible = true
        end
    elseif edit.type == "area" then
        local label = global.player_name_labels and global.player_name_labels[player_index]
        local field = global.player_name_textfields and global.player_name_textfields[player_index]
        local edit_button = global.player_name_buttons and global.player_name_buttons[player_index]
        if label and field and edit_button then
            local new_name = field.text
            if new_name and new_name ~= "" then
                label.caption = new_name
            end
            field.visible = false
            label.visible = true
            edit_button.style.top_margin = 5
        end
    end
    global.active_edit_element[player_index] = nil
end

return gui_helpers