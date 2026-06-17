-- events/gui/group_handlers.lua
local combinator_schedule = require("gui.combinator_schedule")
local popup_template = require("gui.popup_template")
local drone_count_popup = require("gui.popups.drone_count_popup")
local area_drone_popup = require("gui.popups.area_drone_popup")
local task_drone_popup = require("gui.popups.task_drone_popup")
local construction_task_popup = require("gui.popups.construction_task_popup")
local construction_link_popup = require("gui.popups.construction_link_popup")
local logistic_task_popup = require("gui.popups.logistic_task_popup")
local logistic_link_popup = require("gui.popups.logistic_link_popup")
local area_picker_popup = require("gui.popups.area_picker_popup")
local combinator_window = require("gui.combinator_window")

local function find_element_by_name(parent, name)
    if not parent or not parent.valid then return nil end
    for _, child in pairs(parent.children) do
        if child.valid then
            if child.name == name then
                return child
            end
            local found = find_element_by_name(child, name)
            if found then return found end
        end
    end
    return nil
end

local function handle(element, player, player_index, event)
    if not global.active_name_edit then
        global.active_name_edit = {}
    end

    -- ===== ОБРАБОТКА РАДИОКНОПОК В ПОПАПЕ СТРОИТЕЛЬНОЙ СВЯЗИ =====
    if element.name and (element.name:find("_mode_current$") or element.name:find("_mode_multi$")) then
        local popup_name = element.tags and element.tags.popup_name
        if popup_name then
            local frame = player.gui.screen[popup_name]
            if frame and frame.valid and frame.tags then
                local radio_current = frame.tags.radio_current
                local radio_multi = frame.tags.radio_multi
                local current_block = frame.tags.current_block
                local multi_block = frame.tags.multi_block
                if radio_current and radio_current.valid and radio_multi and radio_multi.valid then
                    if element.name:find("_mode_current$") then
                        radio_current.state = true
                        radio_multi.state = false
                    else
                        radio_current.state = false
                        radio_multi.state = true
                    end
                    if current_block then current_block.visible = radio_current.state end
                    if multi_block then multi_block.visible = radio_multi.state end
                end
            end
        end
        return true
    end

    -- ===== Режимы выбора области (для попапов связей и задач) =====
    if element.name and (element.name:find("_link_mode_use_current$") or element.name:find("_link_mode_copy$")) then
        local popup_name = nil
        if element.name:find("_link_mode_use_current$") then
            popup_name = element.name:gsub("_link_mode_use_current$", "")
        elseif element.name:find("_link_mode_copy$") then
            popup_name = element.name:gsub("_link_mode_copy$", "")
        end
        if not popup_name then return true end
        local frame = player.gui.screen[popup_name]
        if frame and frame.valid then
            local opt_current = frame[popup_name .. "_link_mode_use_current"]
            local opt_copy = frame[popup_name .. "_link_mode_copy"]
            local select_block = frame[popup_name .. "_select_area_block"]
            if opt_current and opt_current.valid and opt_copy and opt_copy.valid then
                if element.name:find("_link_mode_use_current$") then
                    opt_current.state = true
                    opt_copy.state = false
                else
                    opt_current.state = false
                    opt_copy.state = true
                end
                if select_block and select_block.valid then
                    select_block.visible = opt_copy.state
                end
            end
        end
        return true
    end

    -- ===== Кнопка "Выбрать область" в старых попапах =====
    if element.name and element.name:find("_select_area_btn$") then
        local popup_name = element.name:gsub("_select_area_btn$", "")
        local frame = player.gui.screen[popup_name]
        if frame and frame.valid then
            local tags = frame.tags
            if tags and tags.unit_number and tags.group_id then
                area_picker_popup.open(player, tags.unit_number, tags.group_id, function(selected_id)
                    if frame and frame.valid then
                        local label = frame[tags.selected_label_name]
                        if label and label.valid then
                            local zone = global.areas[selected_id]
                            if zone then
                                label.caption = zone.name
                                frame.tags.selected_area_id = selected_id
                            else
                                label.caption = "Не выбрана"
                                frame.tags.selected_area_id = nil
                            end
                        end
                    end
                end)
            end
        end
        return true
    end

    -- ===== ГРУППЫ В КОМБИНАТОРЕ (расписание) =====

    -- Добавление группы
    if element.name and element.name:find("^combinator_add_group_") then
        local unit_number = tonumber(element.tags.unit_number)
        if unit_number then
            combinator_schedule.add_group(unit_number)
        end
        return true
    end

    -- Удаление группы
    if element.name and element.name:find("^combinator_group_delete_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        if unit_number and group_id then
            combinator_schedule.delete_group(unit_number, group_id)
        end
        return true
    end

    -- Вкл/выкл группы
    if element.name and element.name:find("^combinator_group_toggle_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        if unit_number and group_id then
            combinator_schedule.toggle_group(unit_number, group_id)
        end
        return true
    end

    -- Перемещение группы вверх
    if element.name and element.name:find("^combinator_group_move_up_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        if unit_number and group_id then
            combinator_schedule.move_group_up(unit_number, group_id)
        end
        return true
    end

    -- Перемещение группы вниз
    if element.name and element.name:find("^combinator_group_move_down_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        if unit_number and group_id then
            combinator_schedule.move_group_down(unit_number, group_id)
        end
        return true
    end

    -- Редактирование имени группы
    if element.name and element.name:find("^combinator_group_edit_name_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        if not unit_number or not group_id then return true end

        if global.active_name_edit[player_index] then
            local prev = global.active_name_edit[player_index]
            if prev.label and prev.label.valid then prev.label.visible = true end
            if prev.field and prev.field.valid then prev.field.visible = false end
            global.active_name_edit[player_index] = nil
        end

        local data = global.combinator_areas[unit_number]
        if not data or not data.schedule_flow or not data.schedule_flow.valid then return true end
        local schedule_flow = data.schedule_flow

        local label_name = string.format("combinator_group_name_label_%d_%d", unit_number, group_id)
        local field_name = string.format("combinator_group_name_field_%d_%d", unit_number, group_id)

        local name_label = find_element_by_name(schedule_flow, label_name)
        local name_field = find_element_by_name(schedule_flow, field_name)

        if name_label and name_field then
            global.active_name_edit[player_index] = { label = name_label, field = name_field, type = "group" }
            name_field.text = name_label.caption
            name_label.visible = false
            name_field.visible = true
            name_field.focus()
        end
        return true
    end

    -- Подтверждение имени группы (Enter)
    if element.name and element.name:find("^combinator_group_name_field_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        local new_name = element.text
        if unit_number and group_id then
            combinator_schedule.set_group_name(unit_number, group_id, new_name)
        end
        if global.active_name_edit[player_index] then
            global.active_name_edit[player_index] = nil
        end
        return true
    end

    -- Слоты количества дронов в группе
    if element.name and (element.name:find("^combinator_group_logistic_slot_") or element.name:find("^combinator_group_construction_slot_")) then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        if unit_number and group_id then
            drone_count_popup.open(player, unit_number, group_id)
        end
        return true
    end

    -- Сохранение количества дронов в группе
    if element.name and element.name:find("^drone_save_button_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        local popup_name = element.tags.popup_name
        if unit_number and group_id then
            local data = global.combinator_areas[unit_number]
            if data then
                for _, group in ipairs(data.groups) do
                    if group.id == group_id then
                        local popup = player.gui.screen[popup_name]
                        if popup and popup.valid then
                            local logistic_text = find_element_by_name(popup, "drone_text_" .. unit_number .. "_" .. group_id .. "_logistic")
                            local construction_text = find_element_by_name(popup, "drone_text_" .. unit_number .. "_" .. group_id .. "_construction")
                            if logistic_text then
                                group.logistic = tonumber(logistic_text.text) or 0
                            end
                            if construction_text then
                                group.construction = tonumber(construction_text.text) or 0
                            end
                        end
                        combinator_schedule.sync_drone_counts_for_group(unit_number, group_id)
                        combinator_schedule.refresh(unit_number)
                        break
                    end
                end
            end
        end
        if popup_name and player.gui.screen[popup_name] then
            player.gui.screen[popup_name].destroy()
        end
        return true
    end

    -- ===== НАСТРОЙКА ДРОНОВ ДЛЯ ОБЛАСТИ =====
    if element.name and element.name:find("^area_drone_slot_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        local area_id = tonumber(element.tags.area_id)
        local kind = element.tags.kind
        if unit_number and group_id and area_id and kind then
            area_drone_popup.open(player, unit_number, group_id, area_id, kind)
        end
        return true
    end

    -- Сохранение настроек дронов для области
    if element.name == "area_drone_save" then
        local unit_number = element.tags.unit_number
        local group_id = element.tags.group_id
        local area_id = element.tags.area_id
        local kind = element.tags.kind
        local popup_name = element.tags.popup_name
        if unit_number and group_id and area_id and kind then
            local popup = player.gui.screen[popup_name]
            if popup and popup.valid then
                local slider = find_element_by_name(popup, "area_drone_slider")
                local auto_check = find_element_by_name(popup, "area_drone_auto")
                local auto_tasks_check = find_element_by_name(popup, "area_drone_auto_tasks")
                if slider then
                    local value = slider.slider_value
                    if auto_check and auto_check.state then
                        combinator_schedule.reset_area_drone_count(unit_number, group_id, area_id, kind)
                    else
                        combinator_schedule.set_area_drone_count(unit_number, group_id, area_id, kind, value)
                    end
                    if auto_tasks_check then
                        combinator_schedule.set_section_auto_distribute(unit_number, group_id, area_id, kind, auto_tasks_check.state)
                    end
                end
            end
        end
        if popup_name and player.gui.screen[popup_name] then
            player.gui.screen[popup_name].destroy()
        end
        return true
    end

    -- ===== НАСТРОЙКА ДРОНОВ ДЛЯ ЗАДАЧИ / СВЯЗИ =====
    if element.name and (element.name:find("^task_item_drone_slot_") or element.name:find("^link_item_drone_slot_")) then
        local unit_number = element.tags.unit_number
        local group_id = element.tags.group_id
        local area_id = element.tags.area_id
        local section_kind = element.tags.section_kind
        local item_kind = element.tags.item_kind
        local item_id = element.tags.item_id
        if unit_number and group_id and area_id and section_kind and item_kind and item_id then
            local data = global.combinator_areas[unit_number]
            local area = nil
            if data and data.areas and data.areas[group_id] then
                for _, a in ipairs(data.areas[group_id]) do
                    if a.id == area_id then area = a; break end
                end
            end
            if area then
                local section = (section_kind == "construction") and area.construction_data or area.logistic_data
                if section and section.auto_distribute_tasks == false then
                    task_drone_popup.open(player, unit_number, group_id, area_id, section_kind, item_kind, item_id)
                else
                    player.print("Автоматическое распределение включено. Отключите его в настройках области, чтобы изменять количество дронов вручную.")
                end
            end
        end
        return true
    end

    -- Сохранение количества дронов для задачи/связи
    if element.name == "task_drone_save" then
        local unit_number = element.tags.unit_number
        local group_id = element.tags.group_id
        local area_id = element.tags.area_id
        local section_kind = element.tags.section_kind
        local item_kind = element.tags.item_kind
        local item_id = element.tags.item_id
        local popup_name = element.tags.popup_name
        if unit_number and group_id and area_id and section_kind and item_kind and item_id then
            local popup = player.gui.screen[popup_name]
            if popup and popup.valid then
                local slider = find_element_by_name(popup, "task_drone_slider")
                if slider then
                    local new_value = slider.slider_value
                    combinator_schedule.set_task_drone_count(unit_number, group_id, area_id, section_kind, item_kind, item_id, new_value)
                end
            end
        end
        if popup_name and player.gui.screen[popup_name] then
            player.gui.screen[popup_name].destroy()
        end
        return true
    end

    -- ===== ОТКРЫТИЕ ПОПАПОВ ДЛЯ ЗАДАЧ (строительство/логистика) =====
    if element.name and element.name:find("^task_item_chest_slot_") then
        local unit_number = element.tags.unit_number
        local group_id = element.tags.group_id
        local area_id = element.tags.area_id
        local section_kind = element.tags.section_kind
        local item_kind = element.tags.item_kind
        local item_id = element.tags.item_id
        if unit_number and group_id and area_id and section_kind and item_kind and item_id then
            if section_kind == "construction" and item_kind == "task" then
                construction_task_popup.open(player, unit_number, group_id, area_id, item_id)
            elseif section_kind == "logistic" and item_kind == "task" then
                logistic_task_popup.open(player, unit_number, group_id, area_id, item_id)
            end
        end
        return true
    end

    -- ===== ОТКРЫТИЕ ПОПАПОВ ДЛЯ СВЯЗЕЙ =====
    if element.name and element.name:find("^link_item_chest_slot_") then
        local unit_number = element.tags.unit_number
        local group_id = element.tags.group_id
        local area_id = element.tags.area_id
        local section_kind = element.tags.section_kind
        local item_kind = element.tags.item_kind
        local item_id = element.tags.item_id
        if unit_number and group_id and area_id and section_kind and item_kind and item_id then
            if section_kind == "construction" and item_kind == "link" then
                construction_link_popup.open(player, unit_number, group_id, area_id, item_id)
            elseif section_kind == "logistic" and item_kind == "link" then
                -- ИСПРАВЛЕНИЕ: передаём item_id
                logistic_link_popup.open(player, unit_number, group_id, area_id, item_id)
            end
        end
        return true
    end

    -- ===== СОХРАНЕНИЕ НАСТРОЕК СВЯЗИ (строительная) =====
    if element.name == "construction_link_save" then
        local unit_number = element.tags.unit_number
        local group_id = element.tags.group_id
        local area_id = element.tags.area_id
        local item_id = element.tags.item_id
        local popup_name = element.tags.popup_name

        if unit_number and group_id and area_id and item_id then
            local data = global.combinator_areas[unit_number]
            if data and data.areas and data.areas[group_id] then
                local area = nil
                for _, a in ipairs(data.areas[group_id]) do
                    if a.id == area_id then
                        area = a
                        break
                    end
                end
                if area and area.construction_data and area.construction_data.links then
                    local link = nil
                    for _, l in ipairs(area.construction_data.links) do
                        if l.id == item_id then
                            link = l
                            break
                        end
                    end
                    if link then
                        local popup = player.gui.screen[popup_name]
                        if popup and popup.valid then
                            local radio_current = popup.tags and popup.tags.radio_current
                            local radio_multi = popup.tags and popup.tags.radio_multi
                            if radio_current and radio_current.valid and radio_multi and radio_multi.valid then
                                if radio_current.state then
                                    link.use_current_area = true
                                    link.areas = nil
                                    link.current_area_id = area.global_area_id
                                else
                                    link.use_current_area = false
                                    link.current_area_id = nil
                                    local selected_areas = {}
                                    local function collect_checks(parent)
                                        for _, child in pairs(parent.children) do
                                            if child.valid then
                                                if child.type == "checkbox" and child.name and child.name:find("^link_area_cb_") then
                                                    if child.state then
                                                        local area_id_from_tag = child.tags and child.tags.area_id
                                                        if area_id_from_tag then
                                                            table.insert(selected_areas, area_id_from_tag)
                                                        end
                                                    end
                                                end
                                                collect_checks(child)
                                            end
                                        end
                                    end
                                    collect_checks(popup)
                                    link.areas = selected_areas
                                end
                                combinator_schedule.refresh(unit_number)
                            end
                        end
                    end
                end
            end
        end
        if popup_name and player.gui.screen[popup_name] then
            player.gui.screen[popup_name].destroy()
        end
        return true
    end

    -- Логистические связи (без изменений)
    if element.name == "logistic_link_save" then
        local popup_name = element.tags.popup_name
        if popup_name and player.gui.screen[popup_name] then
            player.gui.screen[popup_name].destroy()
        end
        return true
    end

    -- Переключение вкладок фильтров в попапе
    if element.name == "open_filters" then
        local frame = element
        while frame and frame.parent do
            frame = frame.parent
            if frame.name and frame.name:find("popup_template_") then break end
        end
        if frame and frame.valid and frame.tags.switch_mode then
            frame.tags.switch_mode("filters")
        end
        return true
    end

    if element.name == "filters_back" then
        local frame = element
        while frame and frame.parent do
            frame = frame.parent
            if frame.name and frame.name:find("popup_template_") then break end
        end
        if frame and frame.valid and frame.tags.switch_mode then
            frame.tags.switch_mode("main")
        end
        return true
    end

    -- Перемещение объектов в строительной задаче
    if element.name and element.name:find("^const_obj_") then
        local unit_number = element.tags.unit_number
        local group_id = element.tags.group_id
        local area_id = element.tags.area_id
        local task_id = element.tags.task_id
        local obj_index = element.tags.obj_index
        if event.button == defines.mouse_button_type.left then
            combinator_schedule.move_construction_object(unit_number, group_id, area_id, task_id, obj_index, -1)
        elseif event.button == defines.mouse_button_type.right then
            combinator_schedule.move_construction_object(unit_number, group_id, area_id, task_id, obj_index, 1)
        end
        local frame = element
        while frame and frame.parent do
            frame = frame.parent
            if frame.name and frame.name:find("popup_template_") then break end
        end
        if frame and frame.valid and frame.tags.switch_mode then
            frame.tags.switch_mode("main")
        end
        return true
    end

    -- Фильтры видимости объектов
    if element.name and element.name:find("^filter_cb_") then
        local unit_number = element.tags.unit_number
        local group_id = element.tags.group_id
        local area_id = element.tags.area_id
        local task_id = element.tags.task_id
        local obj_name = element.tags.obj_name
        local state = element.state
        combinator_schedule.set_construction_object_visibility(unit_number, group_id, area_id, task_id, obj_name, state)
        local frame = element
        while frame and frame.parent do
            frame = frame.parent
            if frame.name and frame.name:find("popup_template_") then break end
        end
        if frame and frame.valid and frame.tags.switch_mode then
            frame.tags.switch_mode("main")
        end
        return true
    end

    -- ===== ДОБАВЛЕНИЕ / УДАЛЕНИЕ ОБЛАСТЕЙ В ГРУППУ =====
    if element.name and element.name:find("^combinator_add_area_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        if unit_number and group_id then
            local any_area_id = nil
            for id, _ in pairs(global.areas) do
                any_area_id = id
                break
            end
            if any_area_id then
                combinator_schedule.add_existing_area(unit_number, group_id, any_area_id)
                local combinator_data = global.combinators[unit_number]
                if combinator_data and combinator_data.entity and combinator_data.entity.valid then
                    combinator_window.open(combinator_data.entity, player)
                end
            else
                player.print("Нет ни одной зоны. Сначала создайте зону через 'Планировщик зон'")
            end
        end
        return true
    end

    if element.name and element.name:find("^combinator_area_delete_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        local area_id = tonumber(element.tags.area_id)
        if unit_number and group_id and area_id then
            combinator_schedule.delete_area(unit_number, group_id, area_id)
        end
        return true
    end

    if element.name and element.name:find("^combinator_area_stop_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        local area_id = tonumber(element.tags.area_id)
        if unit_number and group_id and area_id then
            combinator_schedule.toggle_area(unit_number, group_id, area_id)
        end
        return true
    end

    if element.name and element.name:find("^combinator_area_move_up_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        local area_id = tonumber(element.tags.area_id)
        if unit_number and group_id and area_id then
            combinator_schedule.move_area_up(unit_number, group_id, area_id)
        end
        return true
    end

    if element.name and element.name:find("^combinator_area_move_down_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        local area_id = tonumber(element.tags.area_id)
        if unit_number and group_id and area_id then
            combinator_schedule.move_area_down(unit_number, group_id, area_id)
        end
        return true
    end

    -- ===== ДОБАВЛЕНИЕ ЗАДАЧ И СВЯЗЕЙ =====
    if element.name and element.name:find("^add_construction_task_") then
        local parts = {}
        for token in string.gmatch(element.name, "[^_]+") do
            table.insert(parts, token)
        end
        local unit_number = tonumber(parts[4])
        local group_id = tonumber(parts[5])
        local area_id = tonumber(parts[6])
        if unit_number and group_id and area_id then
            combinator_schedule.add_task(unit_number, group_id, area_id, "construction")
        end
        return true
    end

    if element.name and element.name:find("^add_logistic_task_") then
        local parts = {}
        for token in string.gmatch(element.name, "[^_]+") do
            table.insert(parts, token)
        end
        local unit_number = tonumber(parts[4])
        local group_id = tonumber(parts[5])
        local area_id = tonumber(parts[6])
        if unit_number and group_id and area_id then
            combinator_schedule.add_task(unit_number, group_id, area_id, "logistic")
        end
        return true
    end

    if element.name and element.name:find("^add_construction_link_") then
        local parts = {}
        for token in string.gmatch(element.name, "[^_]+") do
            table.insert(parts, token)
        end
        local unit_number = tonumber(parts[4])
        local group_id = tonumber(parts[5])
        local area_id = tonumber(parts[6])
        if unit_number and group_id and area_id then
            combinator_schedule.add_link(unit_number, group_id, area_id, "construction")
        end
        return true
    end

    if element.name and element.name:find("^add_logistic_link_") then
        local parts = {}
        for token in string.gmatch(element.name, "[^_]+") do
            table.insert(parts, token)
        end
        local unit_number = tonumber(parts[4])
        local group_id = tonumber(parts[5])
        local area_id = tonumber(parts[6])
        if unit_number and group_id and area_id then
            combinator_schedule.add_link(unit_number, group_id, area_id, "logistic")
        end
        return true
    end

    -- ===== УДАЛЕНИЕ ЗАДАЧ И СВЯЗЕЙ =====
    if element.name and element.name:find("^task_item_delete_") then
        local parts = {}
        for token in string.gmatch(element.name, "[^_]+") do
            table.insert(parts, token)
        end
        local unit_number = tonumber(parts[4])
        local group_id = tonumber(parts[5])
        local area_id = tonumber(parts[6])
        local kind = parts[7]
        local item_id = tonumber(parts[8])
        if unit_number and group_id and area_id and kind and item_id then
            combinator_schedule.delete_task(unit_number, group_id, area_id, kind, item_id)
        end
        return true
    end

    if element.name and element.name:find("^link_item_delete_") then
        local parts = {}
        for token in string.gmatch(element.name, "[^_]+") do
            table.insert(parts, token)
        end
        local unit_number = tonumber(parts[4])
        local group_id = tonumber(parts[5])
        local area_id = tonumber(parts[6])
        local kind = parts[7]
        local item_id = tonumber(parts[8])
        if unit_number and group_id and area_id and kind and item_id then
            combinator_schedule.delete_link(unit_number, group_id, area_id, kind, item_id)
        end
        return true
    end

    -- ===== ПЕРЕМЕЩЕНИЕ ЗАДАЧ И СВЯЗЕЙ =====
    if element.name and element.name:find("^task_item_move_up_") then
        local parts = {}
        for token in string.gmatch(element.name, "[^_]+") do
            table.insert(parts, token)
        end
        local unit_number = tonumber(parts[5])
        local group_id = tonumber(parts[6])
        local area_id = tonumber(parts[7])
        local kind = parts[8]
        local item_id = tonumber(parts[9])
        if unit_number and group_id and area_id and kind and item_id then
            combinator_schedule.move_task_up(unit_number, group_id, area_id, kind, item_id)
        end
        return true
    end

    if element.name and element.name:find("^task_item_move_down_") then
        local parts = {}
        for token in string.gmatch(element.name, "[^_]+") do
            table.insert(parts, token)
        end
        local unit_number = tonumber(parts[5])
        local group_id = tonumber(parts[6])
        local area_id = tonumber(parts[7])
        local kind = parts[8]
        local item_id = tonumber(parts[9])
        if unit_number and group_id and area_id and kind and item_id then
            combinator_schedule.move_task_down(unit_number, group_id, area_id, kind, item_id)
        end
        return true
    end

    if element.name and element.name:find("^link_item_move_up_") then
        local parts = {}
        for token in string.gmatch(element.name, "[^_]+") do
            table.insert(parts, token)
        end
        local unit_number = tonumber(parts[5])
        local group_id = tonumber(parts[6])
        local area_id = tonumber(parts[7])
        local kind = parts[8]
        local item_id = tonumber(parts[9])
        if unit_number and group_id and area_id and kind and item_id then
            combinator_schedule.move_link_up(unit_number, group_id, area_id, kind, item_id)
        end
        return true
    end

    if element.name and element.name:find("^link_item_move_down_") then
        local parts = {}
        for token in string.gmatch(element.name, "[^_]+") do
            table.insert(parts, token)
        end
        local unit_number = tonumber(parts[5])
        local group_id = tonumber(parts[6])
        local area_id = tonumber(parts[7])
        local kind = parts[8]
        local item_id = tonumber(parts[9])
        if unit_number and group_id and area_id and kind and item_id then
            combinator_schedule.move_link_down(unit_number, group_id, area_id, kind, item_id)
        end
        return true
    end

    -- ===== РЕДАКТИРОВАНИЕ ИМЕНИ ЗАДАЧИ =====
    if element.name and element.name:find("^task_item_edit_name_") then
        local parts = {}
        for token in string.gmatch(element.name, "[^_]+") do
            table.insert(parts, token)
        end
        local unit_number = tonumber(parts[5])
        local group_id = tonumber(parts[6])
        local area_id = tonumber(parts[7])
        local kind = parts[8]
        local item_id = tonumber(parts[9])
        if not (unit_number and group_id and area_id and kind and item_id) then return true end

        if global.active_name_edit[player_index] then
            local prev = global.active_name_edit[player_index]
            if prev.label and prev.label.valid then prev.label.visible = true end
            if prev.field and prev.field.valid then prev.field.visible = false end
            global.active_name_edit[player_index] = nil
        end

        local data = global.combinator_areas[unit_number]
        if not data or not data.schedule_flow or not data.schedule_flow.valid then return true end
        local schedule_flow = data.schedule_flow

        local label_name = string.format("task_item_name_label_%d_%d_%d_%s_%d", unit_number, group_id, area_id, kind, item_id)
        local field_name = string.format("task_item_name_field_%d_%d_%d_%s_%d", unit_number, group_id, area_id, kind, item_id)

        local target_label = find_element_by_name(schedule_flow, label_name)
        local target_field = find_element_by_name(schedule_flow, field_name)

        if target_label and target_field then
            global.active_name_edit[player_index] = { label = target_label, field = target_field, type = "task" }
            target_field.text = target_label.caption
            target_label.visible = false
            target_field.visible = true
            target_field.focus()
        end
        return true
    end

    -- ===== РЕДАКТИРОВАНИЕ ИМЕНИ СВЯЗИ =====
    if element.name and element.name:find("^link_item_edit_name_") then
        local parts = {}
        for token in string.gmatch(element.name, "[^_]+") do
            table.insert(parts, token)
        end
        local unit_number = tonumber(parts[5])
        local group_id = tonumber(parts[6])
        local area_id = tonumber(parts[7])
        local kind = parts[8]
        local item_id = tonumber(parts[9])
        if not (unit_number and group_id and area_id and kind and item_id) then return true end

        if global.active_name_edit[player_index] then
            local prev = global.active_name_edit[player_index]
            if prev.label and prev.label.valid then prev.label.visible = true end
            if prev.field and prev.field.valid then prev.field.visible = false end
            global.active_name_edit[player_index] = nil
        end

        local data = global.combinator_areas[unit_number]
        if not data or not data.schedule_flow or not data.schedule_flow.valid then return true end
        local schedule_flow = data.schedule_flow

        local label_name = string.format("link_item_name_label_%d_%d_%d_%s_%d", unit_number, group_id, area_id, kind, item_id)
        local field_name = string.format("link_item_name_field_%d_%d_%d_%s_%d", unit_number, group_id, area_id, kind, item_id)

        local target_label = find_element_by_name(schedule_flow, label_name)
        local target_field = find_element_by_name(schedule_flow, field_name)

        if target_label and target_field then
            global.active_name_edit[player_index] = { label = target_label, field = target_field, type = "link" }
            target_field.text = target_label.caption
            target_label.visible = false
            target_field.visible = true
            target_field.focus()
        end
        return true
    end

    -- Подтверждение имени задачи (Enter)
    if element.name and element.name:find("^task_item_name_field_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        local area_id = tonumber(element.tags.area_id)
        local kind = element.tags.section_kind
        local item_id = tonumber(element.tags.item_id)
        local new_name = element.text
        if unit_number and group_id and area_id and kind and item_id then
            combinator_schedule.set_task_name(unit_number, group_id, area_id, kind, item_id, new_name)
        end
        if global.active_name_edit[player_index] then
            global.active_name_edit[player_index] = nil
        end
        return true
    end

    -- Подтверждение имени связи (Enter)
    if element.name and element.name:find("^link_item_name_field_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        local area_id = tonumber(element.tags.area_id)
        local kind = element.tags.section_kind
        local item_id = tonumber(element.tags.item_id)
        local new_name = element.text
        if unit_number and group_id and area_id and kind and item_id then
            combinator_schedule.set_link_name(unit_number, group_id, area_id, kind, item_id, new_name)
        end
        if global.active_name_edit[player_index] then
            global.active_name_edit[player_index] = nil
        end
        return true
    end

    -- Перемещение секций (строительство/логистика) вверх/вниз
    if element.name and element.name:find("^move_construction_section_up_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        local area_id = tonumber(element.tags.area_id)
        if unit_number and group_id and area_id then
            combinator_schedule.move_construction_section_up(unit_number, group_id, area_id)
        end
        return true
    end
    if element.name and element.name:find("^move_construction_section_down_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        local area_id = tonumber(element.tags.area_id)
        if unit_number and group_id and area_id then
            combinator_schedule.move_construction_section_down(unit_number, group_id, area_id)
        end
        return true
    end
    if element.name and element.name:find("^move_logistic_section_up_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        local area_id = tonumber(element.tags.area_id)
        if unit_number and group_id and area_id then
            combinator_schedule.move_logistic_section_up(unit_number, group_id, area_id)
        end
        return true
    end
    if element.name and element.name:find("^move_logistic_section_down_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        local area_id = tonumber(element.tags.area_id)
        if unit_number and group_id and area_id then
            combinator_schedule.move_logistic_section_down(unit_number, group_id, area_id)
        end
        return true
    end

    -- Вкл/выкл секций
    if element.name and element.name:find("^toggle_construction_section_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        local area_id = tonumber(element.tags.area_id)
        if unit_number and group_id and area_id then
            combinator_schedule.toggle_construction_section(unit_number, group_id, area_id)
        end
        return true
    end
    if element.name and element.name:find("^toggle_logistic_section_") then
        local unit_number = tonumber(element.tags.unit_number)
        local group_id = tonumber(element.tags.group_id)
        local area_id = tonumber(element.tags.area_id)
        if unit_number and group_id and area_id then
            combinator_schedule.toggle_logistic_section(unit_number, group_id, area_id)
        end
        return true
    end

    -- Вкл/выкл отдельных задач/связей
    if element.name and element.name:find("^task_item_toggle_") then
        local parts = {}
        for token in string.gmatch(element.name, "[^_]+") do
            table.insert(parts, token)
        end
        local unit_number = tonumber(parts[5])
        local group_id = tonumber(parts[6])
        local area_id = tonumber(parts[7])
        local kind = parts[8]
        local item_id = tonumber(parts[9])
        if unit_number and group_id and area_id and kind and item_id then
            combinator_schedule.toggle_task(unit_number, group_id, area_id, kind, item_id)
        end
        return true
    end
    if element.name and element.name:find("^link_item_toggle_") then
        local parts = {}
        for token in string.gmatch(element.name, "[^_]+") do
            table.insert(parts, token)
        end
        local unit_number = tonumber(parts[5])
        local group_id = tonumber(parts[6])
        local area_id = tonumber(parts[7])
        local kind = parts[8]
        local item_id = tonumber(parts[9])
        if unit_number and group_id and area_id and kind and item_id then
            combinator_schedule.toggle_link(unit_number, group_id, area_id, kind, item_id)
        end
        return true
    end

    return false
end

-- ===== ON_GUI_VALUE_CHANGED =====
local function on_gui_value_changed(event, player)
    local element = event.element
    if not element or not element.valid then return end

    if element.name and element.name:find("^drone_slider_") then
        local text_name = string.gsub(element.name, "^drone_slider_", "drone_text_")
        local root = element
        while root and root.parent and root.parent ~= player.gui.screen do
            root = root.parent
        end
        local textfield = find_element_by_name(root, text_name)
        if textfield then
            textfield.text = tostring(element.slider_value)
        end
    elseif element.name and element.name:find("^drone_text_") then
        local num = tonumber(element.text)
        if num == nil then num = 0 end
        if num > 500 then num = 500 end
        if num < 0 then num = 0 end
        local slider_name = string.gsub(element.name, "^drone_text_", "drone_slider_")
        local root = element
        while root and root.parent and root.parent ~= player.gui.screen do
            root = root.parent
        end
        local slider = find_element_by_name(root, slider_name)
        if slider then
            slider.slider_value = num
        end
    elseif element.name and element.name:find("^area_drone_slider$") then
        local textfield = find_element_by_name(element.parent, "area_drone_text")
        if textfield then
            textfield.text = tostring(element.slider_value)
        end
    elseif element.name and element.name:find("^area_drone_text$") then
        local num = tonumber(element.text) or 0
        if num > 500 then num = 500 end
        if num < 0 then num = 0 end
        element.text = tostring(num)
        local slider = find_element_by_name(element.parent, "area_drone_slider")
        if slider then
            slider.slider_value = num
        end
    elseif element.name and element.name:find("^task_drone_slider$") then
        local textfield = find_element_by_name(element.parent, "task_drone_text")
        if textfield then
            textfield.text = tostring(element.slider_value)
        end
    elseif element.name and element.name:find("^task_drone_text$") then
        local num = tonumber(element.text) or 0
        local slider = find_element_by_name(element.parent, "task_drone_slider")
        if slider then
            if num > slider.maximum_value then num = slider.maximum_value end
            if num < 0 then num = 0 end
            element.text = tostring(num)
            slider.slider_value = num
        end
    end
end

-- ===== ON_GUI_CONFIRMED =====
local function on_gui_confirmed(event, player, player_index)
    if event.element.name and event.element.name:find("^task_item_name_field_") then
        local unit_number = tonumber(event.element.tags.unit_number)
        local group_id = tonumber(event.element.tags.group_id)
        local area_id = tonumber(event.element.tags.area_id)
        local kind = event.element.tags.section_kind
        local item_id = tonumber(event.element.tags.item_id)
        local new_name = event.element.text
        if unit_number and group_id and area_id and kind and item_id then
            combinator_schedule.set_task_name(unit_number, group_id, area_id, kind, item_id, new_name)
        end
        if global.active_name_edit[player_index] then
            global.active_name_edit[player_index] = nil
        end
        return true
    end
    if event.element.name and event.element.name:find("^link_item_name_field_") then
        local unit_number = tonumber(event.element.tags.unit_number)
        local group_id = tonumber(event.element.tags.group_id)
        local area_id = tonumber(event.element.tags.area_id)
        local kind = event.element.tags.section_kind
        local item_id = tonumber(event.element.tags.item_id)
        local new_name = event.element.text
        if unit_number and group_id and area_id and kind and item_id then
            combinator_schedule.set_link_name(unit_number, group_id, area_id, kind, item_id, new_name)
        end
        if global.active_name_edit[player_index] then
            global.active_name_edit[player_index] = nil
        end
        return true
    end
    if event.element.name and event.element.name:find("^combinator_group_name_field_") then
        local unit_number = tonumber(event.element.tags.unit_number)
        local group_id = tonumber(event.element.tags.group_id)
        local new_name = event.element.text
        if unit_number and group_id then
            combinator_schedule.set_group_name(unit_number, group_id, new_name)
        end
        if global.active_name_edit[player_index] then
            global.active_name_edit[player_index] = nil
        end
        return true
    end
    return false
end

return {
    handle = handle,
    on_gui_value_changed = on_gui_value_changed,
    on_gui_confirmed = on_gui_confirmed
}