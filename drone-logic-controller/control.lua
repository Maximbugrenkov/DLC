-- control.lua
local init = require("core.init")
local area = require("core.area")
local combinator = require("combinators.controller")
local dispatcher = require("core.dispatcher")
local rendering = require("core.rendering")
local on_selected_area = require("events.on_selection")
local gui_handlers = require("events.on_gui_click")
local area_manager = require("gui.area_manager")
local area_editor = require("gui.area_editor")
local preview = require("core.preview")
local combinator_window = require("gui.combinator_window")
require("commands.admin")

local test_button = require("gui.test_toggle_button")

combinator.init({
    get_area = area.get_area,
    update_area_priority = area.update_dynamic_priority
})
dispatcher.init({
    get_areas_at_point = area.get_areas_at_point
})

script.on_init(function()
    init.init_global()
    global.player_main_frames = global.player_main_frames or {}
    global.player_name_labels = global.player_name_labels or {}
    global.player_name_textfields = global.player_name_textfields or {}
    global.player_name_buttons = global.player_name_buttons or {}
    global.group_name_labels = global.group_name_labels or {}
    global.task_status_frames = global.task_status_frames or {}
    global.group_name_textfields = global.group_name_textfields or {}
    global.chest_windows = global.chest_windows or {}
    global.combinator_areas = global.combinator_areas or {}
    global.test_button = test_button
    rendering.redraw_all()
    log("DLCP: on_init called")
end)

script.on_load(function()
    init.init_global()
    global.player_main_frames = global.player_main_frames or {}
    global.player_name_labels = global.player_name_labels or {}
    global.player_name_textfields = global.player_name_textfields or {}
    global.player_name_buttons = global.player_name_buttons or {}
    global.group_name_labels = global.group_name_labels or {}
    global.task_status_frames = global.task_status_frames or {}
    global.group_name_textfields = global.group_name_textfields or {}
    global.chest_windows = global.chest_windows or {}
    global.combinator_areas = global.combinator_areas or {}
    global.test_button = test_button
    rendering.redraw_all()
    log("DLCP: on_load called")
end)

script.on_configuration_changed(function()
    init.init_global()
    global.player_main_frames = global.player_main_frames or {}
    global.player_name_labels = global.player_name_labels or {}
    global.player_name_textfields = global.player_name_textfields or {}
    global.player_name_buttons = global.player_name_buttons or {}
    global.group_name_labels = global.group_name_labels or {}
    global.task_status_frames = global.task_status_frames or {}
    global.group_name_textfields = global.group_name_textfields or {}
    global.chest_windows = global.chest_windows or {}
    global.combinator_areas = global.combinator_areas or {}
    -- Миграция старых данных комбинатора в новую структуру
    if global.combinator_groups then
        for unit_number, old_groups in pairs(global.combinator_groups) do
            if not global.combinator_areas[unit_number] then
                global.combinator_areas[unit_number] = { groups = {}, areas = {}, schedule_flow = nil, next_group_id = 1 }
            end
            local new_data = global.combinator_areas[unit_number]
            -- Переносим группы
            for _, old_group in ipairs(old_groups.groups or {}) do
                local new_group = {
                    id = old_group.id,
                    name = old_group.name or "Группа " .. old_group.id,
                    logistic = old_group.logistic or 0,
                    construction = old_group.construction or 0,
                    enabled = (old_group.enabled ~= false),
                    editing_name = false
                }
                table.insert(new_data.groups, new_group)
                if new_data.next_group_id <= new_group.id then new_data.next_group_id = new_group.id + 1 end
                -- Переносим области из records
                if global.combinator_areas[unit_number].records then
                    new_data.areas[new_group.id] = {}
                    for _, rec in ipairs(global.combinator_areas[unit_number].records) do
                        if rec.group_id == new_group.id then
                            table.insert(new_data.areas[new_group.id], rec.area_id)
                        end
                    end
                end
            end
        end
        global.combinator_groups = nil -- очищаем старые данные
    end
    -- Очищаем старый records
    if global.combinator_areas then
        for unit, data in pairs(global.combinator_areas) do
            if data.records then data.records = nil end
            if not data.groups then data.groups = {} end
            if not data.areas then data.areas = {} end
        end
    end
    rendering.redraw_all()
    log("DLCP: configuration changed")
end)

script.on_event(defines.events.on_built_entity, combinator.on_built)
script.on_event(defines.events.on_robot_built_entity, combinator.on_built)
script.on_event(defines.events.script_raised_built, combinator.on_built)
script.on_event(defines.events.script_raised_revive, combinator.on_built)
script.on_event(defines.events.on_player_mined_entity, combinator.on_destroyed)
script.on_event(defines.events.on_robot_mined_entity, combinator.on_destroyed)
script.on_event(defines.events.script_raised_destroy, combinator.on_destroyed)

script.on_event(defines.events.on_player_selected_area, on_selected_area)

script.on_event(defines.events.on_gui_click, gui_handlers.on_gui_click)
script.on_event(defines.events.on_gui_confirmed, gui_handlers.on_gui_confirmed)
script.on_event(defines.events.on_gui_value_changed, gui_handlers.on_gui_value_changed)

script.on_event(defines.events.on_gui_opened, function(event)
    local entity = event.entity
    if entity and entity.name == "drone-logic-controller" then
        local player = game.get_player(event.player_index)
        if player then
            combinator_window.open(entity, player)
        end
    end
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name == "area-manager-shortcut" then
        local player = game.players[event.player_index]
        area_manager.open(player)
    elseif event.prototype_name == "dlc-controller-shortcut" then
        local player = game.players[event.player_index]
        if player and player.valid then
            if player.can_insert({name = "drone-logic-controller", count = 1}) then
                player.insert({name = "drone-logic-controller", count = 1})
            else
                player.print("Инвентарь заполнен, невозможно выдать комбинатор.")
            end
        end
    end
end)

script.on_event("open-area-manager", function(event)
    local player = game.players[event.player_index]
    if player then
        area_manager.open(player)
    end
end)

local UPDATE_INTERVAL = 600
script.on_event(defines.events.on_tick, function(event)
    if global.delayed_window_open then
        for player_index, data in pairs(global.delayed_window_open) do
            if event.tick >= data.tick then
                local player = game.players[player_index]
                if player and player.valid then
                    -- ПРОВЕРЯЕМ, НЕТ ЛИ УЖЕ ОТКРЫТОГО ФРЕЙМА
                    if not global.player_main_frames[player_index] or not global.player_main_frames[player_index].valid then
                        local frame, name_label = area_editor.create_new_area_frame(
                            player, player_index, data.pending)
                        if frame and frame.valid then
                            global.player_main_frames[player_index] = frame
                            global.player_name_labels[player_index] = name_label
                        end
                    end
                end
                global.delayed_window_open[player_index] = nil
            end
        end
    end

    if event.tick % UPDATE_INTERVAL == 0 then
        pcall(combinator.update_all)   -- защита от ошибок
        pcall(dispatcher.evaluate)
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    local element = event.element
    if element and element.valid then
        -- Если это попап с флагом is_popup, вызываем его функцию закрытия (которая сохраняет данные)
        if element.tags and element.tags.is_popup and element.tags.close_func then
            element.tags.close_func()
            return
        end

        if element.name == "area_editor_frame" then
            local player_index = event.player_index
            local pending = global.pending_areas[player_index]
            if pending and pending.blueprint and pending.blueprint.valid then
                pending.blueprint.destroy()
            end
            preview.clear()
            global.pending_areas[player_index] = nil
            global.tile_states[player_index] = nil
            global.player_main_frames[player_index] = nil
            global.player_name_labels[player_index] = nil
            global.player_name_textfields[player_index] = nil
            global.player_name_buttons[player_index] = nil
            if element.valid then
                element.destroy()
            end
        elseif element.name and element.name:find("combinator_schedule_") then
            local player = game.get_player(event.player_index)
            if player then player.opened = nil end
            local unit_number = tonumber(string.match(element.name, "%d+"))
            if unit_number then
                if global.group_edit_state then global.group_edit_state[unit_number] = nil end
                if global.add_group_popups then global.add_group_popups[event.player_index] = nil end
                if global.add_area_popups then global.add_area_popups[event.player_index] = nil end
            end
            element.destroy()
        elseif element.name and element.name:find("add_group_popup_") then
            local unit_number = tonumber(string.match(element.name, "%d+"))
            if unit_number then
                if global.group_edit_state then global.group_edit_state[unit_number] = nil end
                if global.add_group_popups then global.add_group_popups[event.player_index] = nil end
            end
            element.destroy()
        end
    end
end)

log("gui_handlers type: " .. type(gui_handlers))
if not gui_handlers then
    error("Failed to load events.on_gui_click")
end