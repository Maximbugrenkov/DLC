-- gui/combinator_window.lua
local combinator_schedule = require("gui.combinator_schedule")

local combinator_window = {}

function combinator_window.open(entity, player)
    local unit_number = entity.unit_number
    if player.gui.screen["combinator_schedule_" .. unit_number] then
        player.gui.screen["combinator_schedule_" .. unit_number].destroy()
    end

    if not global.combinator_areas then global.combinator_areas = {} end
    if not global.combinator_areas[unit_number] then
        global.combinator_areas[unit_number] = {
            groups = {},
            next_group_id = 1,
            next_area_id = 1,
            next_task_id = 1,
            schedule_flow = nil
        }
    end

    local root_frame = player.gui.screen.add({
        type = "frame",
        name = "combinator_schedule_" .. unit_number,
        direction = "vertical",
        style = "frame"
    })
    root_frame.style.width = 460  -- увеличено с 430
    root_frame.style.height = 680
    root_frame.auto_center = true
    player.opened = root_frame

    local title_flow = root_frame.add({ type = "flow", direction = "horizontal" })
    title_flow.style.height = 32
    title_flow.style.padding = 4
    title_flow.style.horizontal_spacing = 8
    local title_label = title_flow.add({ type = "label", caption = "Drone Logic Controller — Расписание", style = "frame_title" })
    local filler = title_flow.add({ type = "empty-widget", style = "draggable_space" })
    filler.style.horizontally_stretchable = true
    local close_btn = title_flow.add({ type = "sprite-button", name = "combinator_close_schedule_" .. unit_number, sprite = "utility/close", style = "close_button", tags = { unit_number = unit_number } })
    close_btn.style.width = 24
    close_btn.style.height = 24

    -- Внешний тёмный впадающий фрейм
    local deep_frame = root_frame.add({ type = "frame", style = "inside_deep_frame" })
    deep_frame.style.vertically_stretchable = true
    deep_frame.style.horizontally_stretchable = true
    deep_frame.style.padding = 4

    -- Скролл-панель без собственного фона
    local scroll_pane = deep_frame.add({ type = "scroll-pane", style = "naked_scroll_pane" })
    scroll_pane.style.vertically_stretchable = true
    scroll_pane.style.horizontally_stretchable = true

    local schedule_flow = scroll_pane.add({ type = "flow", direction = "vertical", name = "schedule_flow" })
    schedule_flow.style.width = 392
    schedule_flow.style.vertically_stretchable = true
    schedule_flow.style.horizontal_align = "left"

    global.combinator_areas[unit_number].schedule_flow = schedule_flow
    combinator_schedule.refresh(unit_number)
end

function combinator_window.close_all_popups(player_index)
    if global.active_popups and global.active_popups[player_index] then
        for name, frame in pairs(global.active_popups[player_index]) do
            if frame and frame.valid then frame.destroy() end
        end
        global.active_popups[player_index] = {}
    end
end

return combinator_window