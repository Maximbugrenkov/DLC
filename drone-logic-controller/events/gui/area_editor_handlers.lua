-- events/gui/area_editor_handlers.lua
local area = require("core.area")
local rendering = require("core.rendering")
local area_editor = require("gui.area_editor")
local area_manager = require("gui.area_manager")
local core_area = require("core.area")
local core_rendering = require("core.rendering")
local preview = require("core.preview")

local function get_active_frame(player)
    return player.gui.screen.area_editor_frame or player.gui.screen.area_editor_edit_frame
end

-- Вспомогательные функции
local function clear_task_status_frames(player_index)
    if not global.task_status_frames then return end
    for task_id, frame in pairs(global.task_status_frames) do
        if frame.valid and frame.tags and frame.tags.player_index == player_index then
            frame.destroy()
            global.task_status_frames[task_id] = nil
        end
    end
end

local function find_task_by_id(tasks, task_id)
    for _, task in ipairs(tasks) do
        if task.task_id == task_id then return task end
    end
    return nil
end

local function find_entity_by_task(task)
    if not task or not task.position or not task.chest_type then return nil end
    local surface = game.surfaces[1]
    local entities = surface.find_entities_filtered{
        name = task.chest_type,
        position = task.position,
        limit = 1
    }
    return entities[1]
end

local function finish_current_edit(player_index)
    if not global.active_edit_element then global.active_edit_element = {} end
    local edit = global.active_edit_element[player_index]
    if not edit then return end

    if edit.type == "task" then
        local label = global.task_name_labels and global.task_name_labels[edit.id]
        local field = global.task_name_textfields and global.task_name_textfields[edit.id]
        local pending = global.pending_areas[player_index]
        local task = pending and find_task_by_id(pending.tasks, edit.id)
        if label and field and task then
            local new_name = field.text
            if new_name and new_name ~= "" then
                task.custom_name = new_name
                label.caption = new_name
            else
                task.custom_name = nil
                local entity = find_entity_by_task(task)
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

-- rebuild_group_add_task_window (без изменений)
local function rebuild_group_add_task_window(frame, pending, group_id, player_index)
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

local function handle(element, player, player_index)
    -----------------------------------------------
    -- Закрытие редактора областей
    -----------------------------------------------
    if element.name == "close_area_editor" then
        finish_current_edit(player_index)
        clear_task_status_frames(player_index)
        local frame = get_active_frame(player)
        if frame and frame.valid then
            preview.clear()
            global.pending_areas[player_index] = nil
            global.tile_states[player_index] = nil
            global.player_main_frames[player_index] = nil
            global.player_name_labels[player_index] = nil
            global.player_name_textfields[player_index] = nil
            global.player_name_buttons[player_index] = nil
            frame.destroy()
        end
        return true
    end

    -----------------------------------------------
    -- Кнопка "Создать область" / "Сохранить область"
    -----------------------------------------------
    if element.name == "area_create_confirm" then
        finish_current_edit(player_index)
        clear_task_status_frames(player_index)
        local pending = global.pending_areas[player_index]
        if not pending then
            player.print("Ошибка: нет данных области.")
            return true
        end
        local frame = global.player_main_frames[player_index]
        if not frame or not frame.valid then
            frame = get_active_frame(player)
            if not frame or not frame.valid then
                player.print("Ошибка: окно редактора не найдено.")
                return true
            end
            global.player_main_frames[player_index] = frame
        end
        preview.clear()
        local name_label = global.player_name_labels and global.player_name_labels[player_index]
        local area_name = name_label and name_label.valid and name_label.caption or "Область_" .. tostring(math.random(10000))
        local priority = 100
        local tiles = {}
        local min_ax, min_ay, max_ax, max_ay = nil, nil, nil, nil
        for row = 1, pending.height do
            for col = 1, pending.width do
                if pending.grid_states[row][col] then
                    local world_x = pending.min_x + (col - 1)
                    local world_y = pending.min_y + (row - 1)
                    if not tiles[world_x] then tiles[world_x] = {} end
                    tiles[world_x][world_y] = true
                    if min_ax == nil or world_x < min_ax then min_ax = world_x end
                    if max_ax == nil or world_x > max_ax then max_ax = world_x end
                    if min_ay == nil or world_y < min_ay then min_ay = world_y end
                    if max_ay == nil or world_y > max_ay then max_ay = world_y end
                end
            end
        end
        if min_ax == nil then
            player.print("Не выбрано ни одного тайла. Область не создана.")
            return true
        end
        local left_top = {x = min_ax, y = min_ay}
        local right_bottom = {x = max_ax + 1, y = max_ay + 1}

        if pending.existing_area_id then
            -- Режим редактирования существующей области
            local zone = global.areas[pending.existing_area_id]
            if not zone then
                player.print("Ошибка: область не найдена.")
                return true
            end
            zone.name = area_name
            zone.base_priority = priority
            zone.tiles = tiles
            zone.area = {x1 = min_ax, y1 = min_ay, x2 = max_ax + 1, y2 = max_ay + 1}
            -- Сохраняем задачи из pending.tasks (со всеми настройками)
            zone.tasks = {}
            for _, task in ipairs(pending.tasks) do
                table.insert(zone.tasks, {
                    task_id = task.task_id,
                    type = task.chest_type,
                    position = task.position,
                    custom_name = task.custom_name,
                    enabled = task.enabled,
                    group_id = task.group_id,
                    display_order = task.display_order,
                })
            end
            zone.groups = pending.groups or {}
            zone.next_group_id = pending.next_group_id or 1
            zone.filter_visibility = pending.filter_visibility or {
                active_provider = true, passive_provider = true,
                storage = true, buffer = true, requester = true
            }
            core_rendering.draw_zone(zone)
            player.print("Область '" .. area_name .. "' обновлена.")
        else
            -- Создание новой области
            local zone = core_area.create(area_name, priority, left_top, right_bottom, tiles, {0.2, 0.6, 1, 0.5})
            zone.tasks = {}
            for _, task in ipairs(pending.tasks) do
                table.insert(zone.tasks, {
                    task_id = task.task_id,
                    type = task.chest_type,
                    position = task.position,
                    custom_name = task.custom_name,
                    enabled = task.enabled,
                    group_id = task.group_id,
                    display_order = task.display_order,
                })
            end
            zone.groups = pending.groups or {}
            zone.next_group_id = pending.next_group_id or 1
            zone.filter_visibility = pending.filter_visibility or {
                active_provider = true, passive_provider = true,
                storage = true, buffer = true, requester = true
            }
            core_rendering.draw_zone(zone)
            player.print("Область '" .. area_name .. "' создана.")
        end

        global.pending_areas[player_index] = nil
        global.tile_states[player_index] = nil
        if frame and frame.valid then frame.destroy() end
        global.player_main_frames[player_index] = nil
        return true
    end

    -----------------------------------------------
    -- Отмена
    -----------------------------------------------
    if element.name == "area_create_cancel" then
        finish_current_edit(player_index)
        clear_task_status_frames(player_index)
        local frame = global.player_main_frames[player_index]
        if frame and frame.valid then
            preview.clear()
            global.pending_areas[player_index] = nil
            global.tile_states[player_index] = nil
            global.player_main_frames[player_index] = nil
            global.player_name_labels[player_index] = nil
            global.player_name_textfields[player_index] = nil
            global.player_name_buttons[player_index] = nil
            frame.destroy()
        end
        return true
    end

    -----------------------------------------------
    -- Новая область (инструмент)
    -----------------------------------------------
    if element.name == "new_area_button" then
        finish_current_edit(player_index)
        clear_task_status_frames(player_index)
        local frame = global.player_main_frames[player_index]
        if frame and frame.valid then
            preview.clear()
            global.pending_areas[player_index] = nil
            global.tile_states[player_index] = nil
            global.player_main_frames[player_index] = nil
            global.player_name_labels[player_index] = nil
            global.player_name_textfields[player_index] = nil
            global.player_name_buttons[player_index] = nil
            frame.destroy()
        end
        player.insert{name = "area-creator"}
        player.print("Начните выделение новой области.")
        return true
    end

    if element.name == "refresh_tasks_button" then
        area_editor.refresh_tasks_frame(player_index)
        return true
    end

    -----------------------------
    -- Действия со списком областей (area_manager)
    -----------------------------
    if element.name == "refresh_area_list" then area_manager.refresh(player) return true end
    if element.name == "center_area_on_map" then
        local area_id = element.tags.area_id
        local zone = global.areas[area_id]
        if zone then
            local center = { x = (zone.area.x1 + zone.area.x2) / 2, y = (zone.area.y1 + zone.area.y2) / 2 }
            local minimap = player.gui.center.area_manager and player.gui.center.area_manager.area_manager_minimap
            if minimap and minimap.valid then minimap.position = center; minimap.zoom = 0.2 end
            player.zoom_to_world(center, 0.2)
        end
        return true
    end

    if element.name == "edit_area_from_manager" then
        local area_id = element.tags.area_id
        local zone = global.areas[area_id]
        if not zone then return true end

        -- Закрываем диспетчер
        if player.gui.center.area_manager then
            player.gui.center.area_manager.destroy()
        end

        -- Превращаем данные зоны в структуру pending
        local pending = {
            width = zone.area.x2 - zone.area.x1,
            height = zone.area.y2 - zone.area.y1,
            min_x = zone.area.x1,
            min_y = zone.area.y1,
            max_x = zone.area.x2,
            max_y = zone.area.y2,
            grid_states = {},
            tasks = {},
            groups = zone.groups or {},
            next_group_id = zone.next_group_id or 1,
            filter_visibility = zone.filter_visibility or {
                active_provider = true, passive_provider = true,
                storage = true, buffer = true, requester = true
            },
            existing_area_id = area_id
        }

        -- Восстанавливаем grid_states из zone.tiles
        for x, ys in pairs(zone.tiles) do
            for y, _ in pairs(ys) do
                local col = x - pending.min_x + 1
                local row = y - pending.min_y + 1
                if not pending.grid_states[row] then pending.grid_states[row] = {} end
                pending.grid_states[row][col] = true
            end
        end

        -- Копируем задачи со всеми полями
        for _, task_data in ipairs(zone.tasks or {}) do
            local tid = task_data.task_id
            if not tid then
                if not global.next_task_id then global.next_task_id = 1 end
                tid = global.next_task_id
                global.next_task_id = global.next_task_id + 1
            end
            table.insert(pending.tasks, {
                task_id = tid,
                chest_type = task_data.type,
                position = task_data.position,
                custom_name = task_data.custom_name,
                enabled = (task_data.enabled == nil and true) or task_data.enabled,
                group_id = task_data.group_id,
                display_order = task_data.display_order or (#pending.tasks + 1),
                grid_row = math.floor(task_data.position.y - pending.min_y) + 1,
                grid_col = math.floor(task_data.position.x - pending.min_x) + 1,
            })
        end

        -- Сохраняем pending и открываем редактор
        global.pending_areas[player_index] = pending
        global.tile_states[player_index] = {}

        -- Закрываем старый редактор, если открыт
        if player.gui.screen.area_editor_frame then
            player.gui.screen.area_editor_frame.destroy()
        end
        if player.gui.screen.area_editor_edit_frame then
            player.gui.screen.area_editor_edit_frame.destroy()
        end

        local frame, name_label = area_editor.create_edit_area_frame(player, player_index, pending)
        if frame and frame.valid then
            global.player_main_frames[player_index] = frame
            global.player_name_labels[player_index] = name_label
        end
        return true
    end

    if element.name == "delete_area_from_manager" then
        local area_id = element.tags.area_id
        local zone = global.areas[area_id]
        if zone then rendering.erase_zone(area_id); area.remove(area_id); player.print("Область '" .. zone.name .. "' удалена."); area_manager.refresh(player) end
        return true
    end

    if element.name == "create_new_area_from_manager" then
        if player.gui.center.area_manager then player.gui.center.area_manager.destroy() end
        player.insert{name = "area-creator"}
        return true
    end

    if element.name == "close_area_manager" then
        if player.gui.center.area_manager then player.gui.center.area_manager.destroy() end
        return true
    end

    -------------------------------------------------
    -- Группы задач (остальное без изменений, но для полноты оставлено)
    -------------------------------------------------
    if element.name and element.name:find("^group_edit_name_button_") then
        finish_current_edit(player_index)
        local group_id = element.tags.group_id
        local p_index = element.tags.player_index
        local label = global.group_name_labels and global.group_name_labels[group_id]
        local textfield = global.group_name_textfields and global.group_name_textfields[group_id]
        if label and textfield then
            if textfield.visible then
                label.caption = textfield.text
                textfield.visible = false
                label.visible = true
                local pending = global.pending_areas[p_index]
                if pending and pending.groups then
                    for _, group in ipairs(pending.groups) do
                        if group.id == group_id then
                            group.name = textfield.text
                            break
                        end
                    end
                end
                global.active_edit_element[player_index] = nil
            else
                textfield.text = label.caption
                textfield.visible = true
                label.visible = false
                textfield.focus()
                global.active_edit_element[player_index] = {type = "group", id = group_id}
            end
        end
        return true
    end

    if element.name == "add_group_button" then
        local p_index = element.tags.player_index
        local pending = global.pending_areas[p_index]
        if pending then
            if not pending.groups then pending.groups = {} end
            local new_group = { id = pending.next_group_id, name = "Новая группа", enabled = true }
            pending.next_group_id = pending.next_group_id + 1
            table.insert(pending.groups, new_group)
            area_editor.refresh_tasks_frame(p_index)
        end
        return true
    end

    if element.name and element.name:find("^group_delete_button_") then
        local group_id = element.tags.group_id
        local p_index = element.tags.player_index
        local pending = global.pending_areas[p_index]
        if pending and pending.groups then
            for i, group in ipairs(pending.groups) do
                if group.id == group_id then
                    for _, task in ipairs(pending.tasks) do
                        if task.group_id == group_id then task.group_id = nil end
                    end
                    table.remove(pending.groups, i)
                    break
                end
            end
            area_editor.refresh_tasks_frame(p_index)
        end
        return true
    end

    if element.name and element.name:find("^group_add_task_button_") then
        local group_id = tonumber(string.match(element.name, "%d+"))
        local p_index = element.tags.player_index
        local pending = global.pending_areas[p_index]
        if not pending then return true end
        local window_name = "group_add_task_window_" .. group_id
        local existing = player.gui.screen[window_name]
        if existing and existing.valid then
            existing.destroy()
            return true
        end
        local win_frame = player.gui.screen.add{
            type = "frame",
            name = window_name,
            direction = "vertical",
            caption = "Добавление задачи в группу"
        }
        win_frame.auto_center = true
        win_frame.style.width = 380
        win_frame.style.height = 400
        win_frame.style.padding = 8
        local tabs_flow = win_frame.add{
            type = "flow",
            direction = "horizontal",
            name = "group_add_tabs"
        }
        tabs_flow.style.horizontal_spacing = 0
        tabs_flow.style.bottom_margin = 4
        local btn_all = tabs_flow.add{
            type = "button",
            name = "group_add_tab_all",
            caption = "Все",
            tags = { group_id = group_id, player_index = player_index }
        }
        btn_all.style.width = 188
        btn_all.style.font_color = {0.9, 0.9, 0.9}
        local btn_filters = tabs_flow.add{
            type = "button",
            name = "group_add_tab_filters",
            caption = "Фильтры",
            tags = { group_id = group_id, player_index = player_index }
        }
        btn_filters.style.width = 188
        btn_filters.style.font_color = {0.7, 0.7, 0.7}
        local tab_scroll = win_frame.add{
            type = "scroll-pane",
            name = "group_add_tab_scroll",
            style = "naked_scroll_pane"
        }
        tab_scroll.style.vertically_stretchable = false
        tab_scroll.style.horizontally_stretchable = false
        tab_scroll.style.width = 364
        tab_scroll.style.height = 280
        local tab_content = tab_scroll.add{
            type = "flow",
            direction = "vertical",
            name = "group_add_tab_content"
        }
        tab_content.style.vertically_stretchable = true
        tab_content.style.horizontally_stretchable = true
        local tab_all = tab_content.add{
            type = "flow",
            direction = "vertical",
            name = "tab_all"
        }
        tab_all.style.vertically_stretchable = true
        local tab_filters = tab_content.add{
            type = "flow",
            direction = "vertical",
            name = "tab_filters",
            visible = false
        }
        tab_filters.style.vertically_stretchable = true
        rebuild_group_add_task_window(win_frame, pending, group_id, player_index)
        local close_btn = win_frame.add{
            type = "button",
            name = "group_add_task_close_button_" .. group_id,
            caption = "Закрыть",
            style = "back_button",
            tags = { group_id = group_id }
        }
        close_btn.style.top_margin = 8
        return true
    end

    if element.name == "group_add_tab_all" or element.name == "group_add_tab_filters" then
        local group_id = element.tags.group_id
        local p_index = element.tags.player_index
        local win_name = "group_add_task_window_" .. group_id
        local win = player.gui.screen[win_name]
        if not win or not win.valid then return true end
        local tabs = win.group_add_tabs
        local btn_all = tabs.group_add_tab_all
        local btn_filters = tabs.group_add_tab_filters
        local tab_scroll = win.group_add_tab_scroll
        local tab_content = tab_scroll and tab_scroll.group_add_tab_content
        if not tab_content then return true end
        local tab_all = tab_content.tab_all
        local tab_filters = tab_content.tab_filters
        btn_all.style.font_color = {0.7, 0.7, 0.7}
        btn_filters.style.font_color = {0.7, 0.7, 0.7}
        tab_all.visible = false
        tab_filters.visible = false
        if element.name == "group_add_tab_all" then
            btn_all.style.font_color = {0.9, 0.9, 0.9}
            tab_all.visible = true
        else
            btn_filters.style.font_color = {0.9, 0.9, 0.9}
            tab_filters.visible = true
        end
        return true
    end

    if element.name and element.name:find("^group_add_task_item_") then
        local task_id = tonumber(string.match(element.name, "%d+"))
        local group_id = element.tags.group_id
        local p_index = element.tags.player_index
        local pending = global.pending_areas[p_index]
        if not pending then return true end
        local task = find_task_by_id(pending.tasks, task_id)
        if task then
            task.group_id = group_id
            area_editor.refresh_tasks_frame(p_index)
            local win = player.gui.screen["group_add_task_window_" .. group_id]
            if win and win.valid then
                rebuild_group_add_task_window(win, pending, group_id, p_index)
            end
        end
        return true
    end

    if element.name and element.name:find("^group_add_task_close_button_") then
        local group_id = tonumber(string.match(element.name, "%d+"))
        local win = player.gui.screen["group_add_task_window_" .. group_id]
        if win and win.valid then
            win.destroy()
        end
        return true
    end

    if element.name and element.name:find("^group_remove_task_button_") then
        local task_id = tonumber(string.match(element.name, "%d+"))
        local p_index = element.tags.player_index
        local pending = global.pending_areas[p_index]
        if pending and pending.tasks then
            local task = find_task_by_id(pending.tasks, task_id)
            if task then
                task.group_id = nil
                area_editor.refresh_tasks_frame(p_index)
            end
        end
        return true
    end

    if element.name and element.name:find("^group_toggle_button_") then
        local group_id = tonumber(string.match(element.name, "%d+"))
        local p_index = element.tags.player_index
        local pending = global.pending_areas[p_index]
        if pending and pending.groups then
            for _, group in ipairs(pending.groups) do
                if group.id == group_id then
                    group.enabled = not group.enabled
                    local new_sprite = group.enabled and "utility/play" or "utility/stop"
                    element.sprite = new_sprite
                    element.tooltip = group.enabled and "Группа активна" or "Группа остановлена"
                    if pending.tasks then
                        for _, task in ipairs(pending.tasks) do
                            if task.group_id == group_id then
                                task.enabled = group.enabled
                            end
                        end
                    end
                    area_editor.refresh_tasks_frame(p_index)
                    break
                end
            end
        end
        return true
    end

    -- Фильтры
    if element.name and element.name:find("^filter_group_toggle_") then
        local chest_type = string.match(element.name, "^filter_group_toggle_(.+)")
        local p_index = element.tags.player_index
        local pending = global.pending_areas[p_index]
        if pending then
            if not pending.filter_group_enabled then
                pending.filter_group_enabled = {}
            end
            local new_state = not (pending.filter_group_enabled[chest_type] ~= false)
            pending.filter_group_enabled[chest_type] = new_state
            if pending.tasks then
                for _, task in ipairs(pending.tasks) do
                    if task.chest_type == chest_type then
                        task.enabled = new_state
                    end
                end
            end
            area_editor.refresh_tasks_frame(p_index)
        end
        return true
    end

    if element.name and element.name:find("^filter_group_move_up_") then
        local chest_type = string.match(element.name, "^filter_group_move_up_(.+)")
        local p_index = element.tags.player_index
        local pending = global.pending_areas[p_index]
        if pending and pending.filter_order then
            local order = pending.filter_order
            for i = 2, #order do
                if order[i] == chest_type then
                    order[i], order[i-1] = order[i-1], order[i]
                    break
                end
            end
            area_editor.refresh_tasks_frame(p_index)
        end
        return true
    end

    if element.name and element.name:find("^filter_group_move_down_") then
        local chest_type = string.match(element.name, "^filter_group_move_down_(.+)")
        local p_index = element.tags.player_index
        local pending = global.pending_areas[p_index]
        if pending and pending.filter_order then
            local order = pending.filter_order
            for i = 1, #order - 1 do
                if order[i] == chest_type then
                    order[i], order[i+1] = order[i+1], order[i]
                    break
                end
            end
            area_editor.refresh_tasks_frame(p_index)
        end
        return true
    end

    -- Перемещение задач и групп
    if element.name and element.name:find("^task_move_up_") then
        local task_id = tonumber(string.match(element.name, "%d+"))
        local p_index = element.tags.player_index
        local pending = global.pending_areas[p_index]
        if not pending then return true end
        local grid_states = pending.grid_states
        local active_tasks = {}
        for _, task in ipairs(pending.tasks) do
            local row, col = task.grid_row, task.grid_col
            if row and col and grid_states[row] and grid_states[row][col] then
                table.insert(active_tasks, task)
            end
        end
        table.sort(active_tasks, function(a,b) return a.display_order < b.display_order end)
        local idx = nil
        for i, task in ipairs(active_tasks) do
            if task.task_id == task_id then
                idx = i
                break
            end
        end
        if idx and idx > 1 then
            local prev_task = active_tasks[idx - 1]
            local current_task = active_tasks[idx]
            current_task.display_order, prev_task.display_order = prev_task.display_order, current_task.display_order
            area_editor.refresh_tasks_frame(p_index)
        end
        return true
    end

    if element.name and element.name:find("^task_move_down_") then
        local task_id = tonumber(string.match(element.name, "%d+"))
        local p_index = element.tags.player_index
        local pending = global.pending_areas[p_index]
        if not pending then return true end
        local grid_states = pending.grid_states
        local active_tasks = {}
        for _, task in ipairs(pending.tasks) do
            local row, col = task.grid_row, task.grid_col
            if row and col and grid_states[row] and grid_states[row][col] then
                table.insert(active_tasks, task)
            end
        end
        table.sort(active_tasks, function(a,b) return a.display_order < b.display_order end)
        local idx = nil
        for i, task in ipairs(active_tasks) do
            if task.task_id == task_id then
                idx = i
                break
            end
        end
        if idx and idx < #active_tasks then
            local next_task = active_tasks[idx + 1]
            local current_task = active_tasks[idx]
            current_task.display_order, next_task.display_order = next_task.display_order, current_task.display_order
            area_editor.refresh_tasks_frame(p_index)
        end
        return true
    end

    if element.name and element.name:find("^group_move_up_") then
        local group_id = element.tags.group_id
        local p_index = element.tags.player_index
        local pending = global.pending_areas[p_index]
        if pending and pending.groups then
            for i, group in ipairs(pending.groups) do
                if group.id == group_id and i > 1 then
                    pending.groups[i], pending.groups[i-1] = pending.groups[i-1], pending.groups[i]
                    area_editor.refresh_tasks_frame(p_index)
                    break
                end
            end
        end
        return true
    end

    if element.name and element.name:find("^group_move_down_") then
        local group_id = element.tags.group_id
        local p_index = element.tags.player_index
        local pending = global.pending_areas[p_index]
        if pending and pending.groups then
            for i, group in ipairs(pending.groups) do
                if group.id == group_id and i < #pending.groups then
                    pending.groups[i], pending.groups[i+1] = pending.groups[i+1], pending.groups[i]
                    area_editor.refresh_tasks_frame(p_index)
                    break
                end
            end
        end
        return true
    end

    -- Редактирование имени задачи
    if element.name and element.name:find("^task_edit_name_button_") then
        finish_current_edit(player_index)
        local task_id = tonumber(string.match(element.name, "%d+"))
        local p_index = element.tags.player_index
        local label = global.task_name_labels and global.task_name_labels[task_id]
        local textfield = global.task_name_textfields and global.task_name_textfields[task_id]
        local pending = global.pending_areas[p_index]
        local task = pending and find_task_by_id(pending.tasks, task_id)
        if label and textfield and task then
            if textfield.visible then
                local new_custom = textfield.text
                if new_custom ~= "" then
                    task.custom_name = new_custom
                    label.caption = new_custom
                else
                    task.custom_name = nil
                    local entity = find_entity_by_task(task)
                    label.caption = (entity and entity.valid) and entity.localised_name or task.chest_type
                end
                textfield.visible = false
                label.visible = true
                global.active_edit_element[player_index] = nil
            else
                textfield.text = task.custom_name or ""
                textfield.visible = true
                label.visible = false
                textfield.focus()
                global.active_edit_element[player_index] = {type = "task", id = task_id}
            end
        end
        return true
    end

    -- Заглушки кнопок статуса и открытия сундуков
    if element.name and element.name:find("^task_open_button_") then return true end
    if element.name and element.name:find("^task_status_button_") then return true end
    if element.name and element.name:find("^dlc_chest_close_") then
        local task_id = tonumber(string.match(element.name, "%d+"))
        if global.chest_windows and global.chest_windows[task_id] and global.chest_windows[task_id].valid then
            global.chest_windows[task_id].destroy()
            global.chest_windows[task_id] = nil
        end
        return true
    end
    if element.name and element.name:find("^task_status_close_") then
        local task_id = tonumber(string.match(element.name, "%d+"))
        local frame = global.task_status_frames and global.task_status_frames[task_id]
        if frame and frame.valid then
            frame.destroy()
            global.task_status_frames[task_id] = nil
        end
        return true
    end

    return false
end

local function on_gui_confirmed(event, player, player_index)
    if event.element.name and event.element.name:find("^task_name_field_") then
        finish_current_edit(player_index)
        local task_id = tonumber(string.match(event.element.name, "%d+"))
        local new_name = event.element.text
        local pending = global.pending_areas[player_index]
        if pending and pending.tasks then
            local task = find_task_by_id(pending.tasks, task_id)
            if task then
                if new_name ~= "" then
                    task.custom_name = new_name
                else
                    task.custom_name = nil
                end
                area_editor.refresh_tasks_frame(player_index)
                player.print("Имя задачи изменено.")
            end
        end
        return true
    end
    if event.element.name and event.element.name:find("^group_name_field_") then
        finish_current_edit(player_index)
        local group_id = event.element.tags.group_id
        local new_name = event.element.text
        local p_index = event.element.tags.player_index
        local pending = global.pending_areas[p_index]
        if pending and pending.groups then
            for _, group in ipairs(pending.groups) do
                if group.id == group_id then
                    group.name = new_name
                    break
                end
            end
            area_editor.refresh_tasks_frame(p_index)
        end
        return true
    end
    return false
end

return {
    handle = handle,
    on_gui_value_changed = function() end,
    on_gui_confirmed = on_gui_confirmed,
}