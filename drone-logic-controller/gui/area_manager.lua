-- gui/area_manager.lua
local area = require("core.area")
local area_editor = require("gui.area_editor")
local core_rendering = require("core.rendering")

local area_manager = {}

function area_manager.open(player)
    if player.gui.center.area_manager then
        player.gui.center.area_manager.destroy()
    end

    local frame = player.gui.center.add{
        type = "frame",
        name = "area_manager",
        caption = "Диспетчер областей",
        direction = "vertical"
    }
    frame.style.width = 500
    frame.style.height = 400
    frame.style.padding = 8

    local header = frame.add{type = "flow", direction = "horizontal"}
    header.add{type = "label", caption = "Области:", style = "caption_label"}
    header.add{type = "empty-widget", style = "draggable_space"}
    header.add{type = "button", name = "refresh_area_list", caption = "↺", style = "tool_button"}

    local scroll = frame.add{type = "scroll-pane"}
    scroll.style.vertically_stretchable = true
    scroll.style.horizontally_stretchable = true

    local list = scroll.add{type = "table", column_count = 1}
    list.style.horizontally_stretchable = true

    for id, zone in pairs(global.areas) do
        local row = list.add{type = "flow", direction = "vertical"}
        row.style.padding = 4
        row.style.bottom_padding = 4

        local name_label = row.add{type = "label", caption = zone.name, style = "bold_label"}
        local info_flow = row.add{type = "flow", direction = "horizontal"}
        info_flow.add{type = "label", caption = "Приоритет: " .. (zone.dynamic_priority or zone.base_priority)}

        local actions = row.add{type = "flow", direction = "horizontal"}
        actions.style.top_padding = 2

        local edit_btn = actions.add{type = "button", name = "edit_area_from_manager", caption = "Редактировать"}
        edit_btn.tags = {area_id = id}

        local delete_btn = actions.add{type = "button", name = "delete_area_from_manager", caption = "Удалить"}
        delete_btn.tags = {area_id = id}
    end

    local bottom_flow = frame.add{type = "flow", direction = "horizontal"}
    bottom_flow.style.horizontal_align = "center"
    bottom_flow.style.top_padding = 8
    bottom_flow.add{type = "button", name = "create_new_area_from_manager", caption = "Создать новую область", style = "confirm_button"}
    bottom_flow.add{type = "button", name = "close_area_manager", caption = "Закрыть", style = "back_button"}
end

function area_manager.refresh(player)
    if player.gui.center.area_manager then
        player.gui.center.area_manager.destroy()
        area_manager.open(player)
    end
end

return area_manager