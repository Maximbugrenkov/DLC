-- events/on_gui_click.lua
local general = require("events.gui.general")
local area_editor_handlers = require("events.gui.area_editor_handlers")
local task_handlers = require("events.gui.task_handlers")
local group_handlers = require("events.gui.group_handlers")
local combinator_handlers = require("events.gui.combinator_handlers")
local combinator_window = require("gui.combinator_window")

local function on_gui_click(event)
    local element = event.element
    if not element or not element.valid then return end
    local player = game.players[event.player_index]
    local player_index = event.player_index

    -- НОВОЕ: если клик на кнопку, имя которой оканчивается на "_close",
    -- и у её родительского окна (попапа) есть close_func, вызываем её и выходим.
    -- Это чинит закрытие попапов с сохранением, не ломая другие кнопки.
    if element.name and string.sub(element.name, -6) == "_close" then
        -- Ищем родительский frame (попап)
        local parent = element.parent
        while parent do
            if parent.type == "frame" and parent.tags and parent.tags.close_func then
                parent.tags.close_func()
                return
            end
            parent = parent.parent
        end
    end

    if not element.gui then
        combinator_window.close_main_window(player)
        combinator_window.close_all_popups(player_index)
        return
    end

    if global.active_popups and global.active_popups[player_index] then
        local clicked_on_popup = false
        local current = element
        while current do
            for name, popup in pairs(global.active_popups[player_index]) do
                if current == popup then
                    clicked_on_popup = true
                    break
                end
            end
            if clicked_on_popup then break end
            current = current.parent
        end
        if not clicked_on_popup then
            combinator_window.close_all_popups(player_index)
        end
    end

    -- Обработка закрытия попапов через крестик (старая логика, оставляем на всякий случай)
    if element.name and element.name:find("_close$") then
        local popup = element.parent.parent
        if popup and popup.valid then
            if popup.tags and popup.tags.close_func then
                popup.tags.close_func()
            else
                popup.destroy()
            end
        end
        return
    end

    -- Выбор области из попапа
    if element.name and element.name:find("^area_select_") then
        local unit_number = element.tags.unit_number
        local group_id = element.tags.group_id
        local area_id = element.tags.area_id
        local popup_key = element.tags.popup_key
        if unit_number and group_id and area_id then
            local popup = player.gui.screen[popup_key]
            if popup and popup.valid then
                if popup.tags and popup.tags.callback then
                    popup.tags.callback(area_id)
                end
                popup.destroy()
            end
        end
        return true
    end

    -- Передаём event в обработчики
    if general.handle(element, player, player_index, event) then return end
    if area_editor_handlers.handle(element, player, player_index, event) then return end
    if task_handlers.handle(element, player, player_index, event) then return end
    if group_handlers.handle(element, player, player_index, event) then return end
    if combinator_handlers.handle(element, player, player_index, event) then return end
end

local function on_gui_value_changed(event)
    local element = event.element
    if not element or not element.valid then return end
    local player = game.players[event.player_index]
    if not player then return end

    general.on_gui_value_changed(event, player)
    group_handlers.on_gui_value_changed(event, player)
end

local function on_gui_confirmed(event)
    local element = event.element
    if not element or not element.valid then return end
    local player = game.players[event.player_index]
    if not player then return end
    local player_index = event.player_index

    pcall(general.on_gui_confirmed, event, player, player_index)
    pcall(area_editor_handlers.on_gui_confirmed, event, player, player_index)
    pcall(group_handlers.on_gui_confirmed, event, player, player_index)
end

local function on_gui_hover(event) end
local function on_gui_leave(event) end

return {
    on_gui_click = on_gui_click,
    on_gui_hover = on_gui_hover,
    on_gui_leave = on_gui_leave,
    on_gui_confirmed = on_gui_confirmed,
    on_gui_value_changed = on_gui_value_changed
}