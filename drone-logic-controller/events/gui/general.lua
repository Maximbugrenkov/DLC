-- events/gui/general.lua
local preview = require("core.preview")
local area_editor = require("gui.area_editor")

local function get_active_frame(player)
    return player.gui.screen.area_editor_frame or player.gui.screen.area_editor_edit_frame
end

local function handle(element, player, player_index)
    -- Закрытие попапов (без изменений)
    if global.add_area_popups and global.add_area_popups[player_index] and global.add_area_popups[player_index].valid then
        local popup = global.add_area_popups[player_index]
        local is_child = false
        local current = element
        while current do
            if current == popup then is_child = true; break end
            current = current.parent
        end
        if not is_child then
            popup.destroy()
            global.add_area_popups[player_index] = nil
            global.add_area_popup_unit[player_index] = nil
            return true
        end
    end
    if global.add_group_popups and global.add_group_popups[player_index] and global.add_group_popups[player_index].valid then
        local popup = global.add_group_popups[player_index]
        local is_child = false
        local current = element
        while current do
            if current == popup then is_child = true; break end
            current = current.parent
        end
        if not is_child then
            popup.destroy()
            global.add_group_popups[player_index] = nil
            return true
        end
    end
    if global.edit_group_drone_popups and global.edit_group_drone_popups[player_index] and global.edit_group_drone_popups[player_index].valid then
        local popup = global.edit_group_drone_popups[player_index]
        local is_child = false
        local current = element
        while current do
            if current == popup then is_child = true; break end
            current = current.parent
        end
        if not is_child then
            popup.destroy()
            global.edit_group_drone_popups[player_index] = nil
            return true
        end
    end

    -- Тестовая кнопка
    if element and (element.name == "test_toggle_button_gray" or element.name == "test_toggle_button_blue") and global.test_button then
        global.test_button.on_click(event)
        return true
    end

    -- Редактирование имени области
    if element and element.name == "area_name_edit_button" then
        if global.active_edit_element and global.active_edit_element[player_index] then
            local edit = global.active_edit_element[player_index]
            if edit.type == "task" then
                local label = global.task_name_labels and global.task_name_labels[edit.id]
                local field = global.task_name_textfields and global.task_name_textfields[edit.id]
                local pending = global.pending_areas[player_index]
                local task = pending and (function(tasks, id) for _,t in ipairs(tasks) do if t.task_id==id then return t end end end)(pending.tasks, edit.id)
                if label and field and task then
                    local new_name = field.text
                    if new_name ~= "" then task.custom_name = new_name; label.caption = new_name
                    else task.custom_name = nil; local ent = (function(t) if not t then return nil end local s=game.surfaces[1]; return s.find_entities_filtered{name=t.chest_type, position=t.position, limit=1}[1] end)(task); label.caption = (ent and ent.valid) and ent.localised_name or task.chest_type end
                    field.visible = false; label.visible = true
                end
            elseif edit.type == "group" then
                local label = global.group_name_labels and global.group_name_labels[edit.id]
                local field = global.group_name_textfields and global.group_name_textfields[edit.id]
                local pending = global.pending_areas[player_index]
                if label and field and pending then
                    local new_name = field.text
                    for _, g in ipairs(pending.groups) do if g.id==edit.id then g.name = (new_name~="" and new_name) or "Новая группа"; label.caption = g.name; break end end
                    field.visible = false; label.visible = true
                end
            end
            global.active_edit_element[player_index] = nil
        end

        local textfield = global.player_name_textfields and global.player_name_textfields[player_index]
        local label = global.player_name_labels and global.player_name_labels[player_index]
        local edit_button = element
        if textfield and label then
            if textfield.visible then
                local new_name = textfield.text
                if new_name and new_name ~= "" then
                    label.caption = new_name
                    player.print("Имя области изменено на: " .. new_name)
                else
                    player.print("Имя не может быть пустым")
                end
                textfield.visible = false
                label.visible = true
                edit_button.style.top_margin = 5
            else
                textfield.text = label.caption
                textfield.visible = true
                label.visible = false
                edit_button.style.top_margin = 7
                textfield.focus()
                global.active_edit_element = global.active_edit_element or {}
                global.active_edit_element[player_index] = {type = "area", id = player_index}
            end
        end
        return true
    end

    -- Ячейки редактора области
    if element and element.name and string.sub(element.name, 1, 5) == "cell_" then
        local tags = element.tags
        if tags and tags.player_index and tags.row and tags.col then
            local p_index = tags.player_index
            local row = tags.row
            local col = tags.col
            if p_index == player_index then
                local states = global.tile_states and global.tile_states[p_index]
                if states and states[row] then
                    local new_state = not states[row][col]
                    states[row][col] = new_state
                    local pending = global.pending_areas[p_index]
                    if pending and pending.grid_states and pending.grid_states[row] then
                        pending.grid_states[row][col] = new_state
                    end
                    local chest_type = nil
                    if pending and pending.logistic_chests then
                        for _, chest in ipairs(pending.logistic_chests) do
                            if chest.grid_row == row and chest.grid_col == col then
                                chest_type = chest.type
                                break
                            end
                        end
                    end
                    local sprite_name
                    if not chest_type then
                        sprite_name = new_state and "dlc_cell_blue" or "dlc_cell_gray"
                    else
                        local suffix_map = {
                            ["active-provider-chest"] = "active_provider",
                            ["passive-provider-chest"] = "passive_provider",
                            ["storage-chest"] = "storage",
                            ["buffer-chest"] = "buffer",
                            ["requester-chest"] = "requester",
                        }
                        local suffix = suffix_map[chest_type] or "active_provider"
                        if new_state then
                            sprite_name = "dlc_cell_blue_" .. suffix
                        else
                            sprite_name = "dlc_cell_gray_" .. suffix
                        end
                    end
                    element.sprite = sprite_name
                    preview.update_from_pending(p_index)
                    area_editor.refresh_tasks_frame(p_index)
                end
            end
        end
        return true
    end

    -- Переключение вкладок (Все / Группы / Фильтры) – исправлено для обоих фреймов
    if element.name == "tasks_tab_all" or element.name == "tasks_tab_groups" or element.name == "tasks_tab_filters" then
        local frame = get_active_frame(player)
        if not frame or not frame.valid then return false end
        local tabs_flow = frame.content_flow.main_content_flow.left_panel.left_vertical_flow.left_scroll_pane.left_vertical_flow_content.dlc_frame_3.children[1].tasks_tabs_flow
        if not tabs_flow then return false end
        local tab_content = frame.content_flow.main_content_flow.left_panel.left_vertical_flow.left_scroll_pane.left_vertical_flow_content.dlc_frame_3.children[1].tasks_tab_content
        if not tab_content then return false end
        local btn_all = tabs_flow.tasks_tab_all
        local btn_groups = tabs_flow.tasks_tab_groups
        local btn_filters = tabs_flow.tasks_tab_filters
        local panel_all = tab_content.tasks_panel_all
        local panel_groups = tab_content.tasks_panel_groups
        local panel_filters = tab_content.tasks_panel_filters
        btn_all.toggled = false
        btn_groups.toggled = false
        btn_filters.toggled = false
        btn_all.style.font_color = {0.7, 0.7, 0.7}
        btn_groups.style.font_color = {0.7, 0.7, 0.7}
        btn_filters.style.font_color = {0.7, 0.7, 0.7}
        panel_all.visible = false
        panel_groups.visible = false
        panel_filters.visible = false
        if element.name == "tasks_tab_all" then
            btn_all.toggled = true
            btn_all.style.font_color = {0.9, 0.9, 0.9}
            panel_all.visible = true
            area_editor.refresh_tasks_frame(player_index)
        elseif element.name == "tasks_tab_groups" then
            btn_groups.toggled = true
            btn_groups.style.font_color = {0.9, 0.9, 0.9}
            panel_groups.visible = true
            area_editor.refresh_tasks_frame(player_index)
        elseif element.name == "tasks_tab_filters" then
            btn_filters.toggled = true
            btn_filters.style.font_color = {0.9, 0.9, 0.9}
            panel_filters.visible = true
            area_editor.refresh_tasks_frame(player_index)
        end
        return true
    end

    -- Кнопка фильтра видимости
    if element.name == "filter_visibility_button" then
        local existing = global.filter_visibility_window and global.filter_visibility_window[player_index]
        if existing and existing.valid then
            existing.destroy()
            global.filter_visibility_window[player_index] = nil
            return true
        end
        local pending = global.pending_areas[player_index]
        if not pending then return true end
        local win_frame = player.gui.screen.add{
            type = "frame",
            name = "filter_visibility_window",
            direction = "vertical",
            caption = "Настройка видимости фильтров"
        }
        win_frame.auto_center = true
        win_frame.style.width = 260
        win_frame.style.padding = 12
        global.filter_visibility_window = global.filter_visibility_window or {}
        global.filter_visibility_window[player_index] = win_frame
        local flow = win_frame.add{type = "flow", direction = "vertical"}
        flow.style.vertical_spacing = 4
        flow.add{type = "label", caption = "Показывать задачи:", style = "caption_label"}
        local CHEST_TYPES = {"active-provider-chest", "passive-provider-chest", "storage-chest", "buffer-chest", "requester-chest"}
        local CHEST_NAMES = {
            ["active-provider-chest"] = "Активные провайдеры",
            ["passive-provider-chest"] = "Пассивные провайдеры",
            ["storage-chest"] = "Складские сундуки",
            ["buffer-chest"] = "Буферные сундуки",
            ["requester-chest"] = "Реквесторы",
        }
        for _, chest_type in ipairs(CHEST_TYPES) do
            local checkbox = flow.add{
                type = "checkbox",
                name = "filter_vis_checkbox_" .. chest_type,
                caption = CHEST_NAMES[chest_type] or chest_type,
                state = pending.filter_visibility[chest_type] ~= false,
                tags = { player_index = player_index, chest_type = chest_type }
            }
            checkbox.style.width = 220
        end
        local close_btn = flow.add{
            type = "button",
            name = "filter_vis_close_button",
            caption = "Закрыть",
            style = "back_button"
        }
        close_btn.tags = { player_index = player_index }
        return true
    end

    -- Закрытие окна фильтра видимости
    if element.name == "filter_vis_close_button" then
        local p_idx = element.tags.player_index
        local win = global.filter_visibility_window and global.filter_visibility_window[p_idx]
        if win and win.valid then
            win.destroy()
            global.filter_visibility_window[p_idx] = nil
        end
        return true
    end

    -- Чекбоксы в окне фильтра видимости
    if element.type == "checkbox" and element.name:find("^filter_vis_checkbox_") then
        local chest_type = element.tags.chest_type
        local p_index = element.tags.player_index
        local pending = global.pending_areas[p_index]
        if pending and pending.filter_visibility then
            pending.filter_visibility[chest_type] = element.state
            area_editor.refresh_tasks_frame(p_index)
        end
        return true
    end

    -- Заглушки кнопок
    if element.name == "copy_area_button" then player.print("Копирование области пока не реализовано.") return true end
    if element.name == "refresh_area_button" then player.print("Обновление списка объектов пока не реализовано.") return true end
    if element.name == "delete_item_button" then player.print("Удаление предмета из инвентаря пока не реализовано.") return true end
    if element.name == "delete_area_button" then player.print("Удаление области отменено.") return true end
    if element.name == "preview_obj" then return true end
    if element.name == "name_edit_ok" then
        local dialog = element.parent.parent
        local textfield = dialog.edit_name_field
        local new_name = textfield and textfield.text
        if new_name and new_name ~= "" then
            local name_label = global.player_name_labels[player_index]
            if name_label and name_label.valid then
                name_label.caption = new_name
                player.print("Имя изменено на: " .. new_name)
            end
        end
        dialog.destroy()
        return true
    end
    if element.name == "name_edit_cancel" then element.parent.parent.destroy() return true end
    if element.name == "btn_import_string" or element.name == "btn_export_string" or element.name == "btn_import_blueprint" then
        player.print("Функция '" .. element.caption .. "' ещё не реализована.")
        return true
    end
    if element.name:find("^tab_") then player.print("Вкладка '" .. element.caption .. "' пока не активна.") return true end

    return false
end

local function on_gui_value_changed(event, player)
    local element = event.element
    if not element or not element.valid then return end
    if element.name and element.name:find("^qty_slider_") then
        local unit_number = element.tags.unit_number
        local slider_value = element.slider_value
        local textfield_name = "qty_textfield_" .. unit_number
        local popup = player.gui.screen["quantity_popup_" .. unit_number]
        if popup and popup.valid then
            local textfield = nil
            for _, child in pairs(popup.children) do
                if child.valid and child.type == "flow" then
                    for _, subchild in pairs(child.children) do
                        if subchild.valid and subchild.name == textfield_name then
                            textfield = subchild
                            break
                        end
                    end
                end
            end
            if textfield then
                textfield.text = tostring(slider_value)
            end
        end
    elseif element.name and element.name:find("^qty_textfield_") then
        local unit_number = element.tags.unit_number
        local text = element.text
        local num = tonumber(text)
        if num == nil then num = 0 end
        if num > 500 then num = 500 end
        if num < 0 then num = 0 end
        local slider_name = "qty_slider_" .. unit_number
        local popup = player.gui.screen["quantity_popup_" .. unit_number]
        if popup and popup.valid then
            local slider = nil
            for _, child in pairs(popup.children) do
                if child.valid and child.type == "flow" then
                    for _, subchild in pairs(child.children) do
                        if subchild.valid and subchild.name == slider_name then
                            slider = subchild
                            break
                        end
                    end
                end
            end
            if slider then
                slider.slider_value = num
            end
        end
    end
end

local function on_gui_confirmed(event, player, player_index)
    if event.element.name == "area_name_textfield" then
        if global.active_edit_element and global.active_edit_element[player_index] then
            local edit = global.active_edit_element[player_index]
            if edit.type == "area" then
                local label = global.player_name_labels and global.player_name_labels[player_index]
                local field = global.player_name_textfields and global.player_name_textfields[player_index]
                if label and field then
                    local new_name = field.text
                    if new_name and new_name ~= "" then label.caption = new_name end
                    field.visible = false
                    label.visible = true
                    local edit_button = global.player_name_buttons and global.player_name_buttons[player_index]
                    if edit_button then edit_button.style.top_margin = 5 end
                end
            end
            global.active_edit_element[player_index] = nil
        end
        local textfield = event.element
        local label = global.player_name_labels and global.player_name_labels[player_index]
        local edit_button = global.player_name_buttons and global.player_name_buttons[player_index]
        if label and label.valid and edit_button then
            local new_name = textfield.text
            if new_name and new_name ~= "" then
                label.caption = new_name
                player.print("Имя области изменено на: " .. new_name)
            end
        end
        textfield.visible = false
        if label then label.visible = true end
        if edit_button then edit_button.style.top_margin = 5 end
        return true
    end
    return false
end

return {
    handle = handle,
    on_gui_value_changed = on_gui_value_changed,
    on_gui_confirmed = on_gui_confirmed,
}