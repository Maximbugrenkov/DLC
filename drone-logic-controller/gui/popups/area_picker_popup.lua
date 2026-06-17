-- gui/popups/area_picker_popup.lua
local area_picker_popup = {}

function area_picker_popup.open(player, unit_number, group_id, callback)
    local popup_key = string.format("area_picker_%d_%d", unit_number, group_id)
    if player.gui.screen[popup_key] then
        player.gui.screen[popup_key].destroy()
    end

    local frame = player.gui.screen.add({
        type = "frame",
        name = popup_key,
        direction = "vertical",
        style = "frame"
    })
    frame.style.width = 300
    frame.style.height = 400
    frame.auto_center = true

    -- Заголовок
    local title_flow = frame.add({ type = "flow", direction = "horizontal" })
    title_flow.style.width = 300
    title_flow.style.vertical_align = "center"
    title_flow.add({ type = "label", caption = "Выберите область", style = "frame_title" })
    local spacer = title_flow.add({ type = "empty-widget" })
    spacer.style.horizontally_stretchable = true
    local close_btn = title_flow.add({
        type = "sprite-button",
        sprite = "utility/close",
        style = "close_button",
        name = popup_key .. "_close"
    })
    close_btn.style.width = 24
    close_btn.style.height = 24

    -- Список областей
    local scroll = frame.add({ type = "scroll-pane" })
    scroll.style.vertically_stretchable = true
    local list = scroll.add({ type = "flow", direction = "vertical" })
    list.style.width = 280
    list.style.vertical_spacing = 2

    for id, zone in pairs(global.areas or {}) do
        local btn = list.add({
            type = "button",
            name = string.format("area_select_%d_%d_%d", unit_number, group_id, id),
            caption = zone.name,
            style = "list_box_item"
        })
        btn.style.horizontally_stretchable = true
        btn.tags = {
            unit_number = unit_number,
            group_id = group_id,
            area_id = id,
            popup_key = popup_key
        }
    end

    if not global.active_popups then global.active_popups = {} end
    global.active_popups[player.index] = global.active_popups[player.index] or {}
    global.active_popups[player.index][popup_key] = frame

    frame.tags.callback = callback
end

return area_picker_popup