-- gui/popup_template.lua
local popup_template = {}

local popup_counter = 0

function popup_template.open(player, title, content_builder, params, width)
    if not player or not player.valid then return end
    width = width or 392

    popup_counter = popup_counter + 1
    local popup_name = "popup_template_" .. popup_counter .. "_" .. tostring(math.random(10000))

    if player.gui.screen[popup_name] then
        player.gui.screen[popup_name].destroy()
    end

    local frame = player.gui.screen.add({
        type = "frame",
        name = popup_name,
        direction = "vertical",
        style = "frame"
    })
    frame.style.width = width
    frame.style.minimal_height = 120
    frame.auto_center = true

    -- Заголовок
    local title_flow = frame.add({ type = "flow", direction = "horizontal" })
    title_flow.style.height = 32
    title_flow.style.padding = {4,4,4,4}
    title_flow.style.horizontal_spacing = 8
    title_flow.style.vertical_align = "center"

    local title_label = title_flow.add({
        type = "label",
        caption = title,
        style = "frame_title"
    })
    title_label.style.maximal_width = width - 60

    local drag_area = title_flow.add({
        type = "empty-widget",
        style = "draggable_space_header"
    })
    drag_area.style.horizontally_stretchable = true
    drag_area.style.height = 24
    drag_area.drag_target = frame

    local close_btn = title_flow.add({
        type = "sprite-button",
        name = popup_name .. "_close",
        sprite = "utility/close",
        style = "close_button",
        tags = { popup_name = popup_name }
    })
    close_btn.style.width = 24
    close_btn.style.height = 24

    -- Внутренняя рамка для содержимого
    local inner_frame = frame.add({
        type = "frame",
        style = "inside_shallow_frame"
    })
    inner_frame.style.margin = {6,6,6,6}
    inner_frame.style.padding = {8,8,8,8}
    inner_frame.style.vertically_stretchable = true
    inner_frame.style.horizontally_stretchable = true

    local content_flow = inner_frame.add({
        type = "flow",
        direction = "vertical"
    })
    content_flow.style.vertically_stretchable = true
    content_flow.style.horizontally_stretchable = true

    if content_builder then
        content_builder(content_flow, params, frame, popup_name)
    end

    if not global.active_popups then global.active_popups = {} end
    if not global.active_popups[player.index] then global.active_popups[player.index] = {} end
    global.active_popups[player.index][popup_name] = frame

    local function close()
        if frame and frame.valid then
            frame.destroy()
        end
        if global.active_popups and global.active_popups[player.index] then
            global.active_popups[player.index][popup_name] = nil
        end
    end

    frame.tags = frame.tags or {}
    frame.tags.close_func = close
    frame.tags.is_popup = true   -- для распознавания в on_gui_closed

    return frame, content_flow
end

function popup_template.close_for_player(player, popup_name)
    if not player or not player.valid then return end
    local frame = player.gui.screen[popup_name]
    if frame and frame.valid then
        if frame.tags and frame.tags.close_func then
            frame.tags.close_func()
        else
            frame.destroy()
        end
    end
    if global.active_popups and global.active_popups[player.index] then
        global.active_popups[player.index][popup_name] = nil
    end
end

return popup_template