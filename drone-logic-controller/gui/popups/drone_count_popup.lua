-- gui/popups/drone_count_popup.lua
local popup_template = require("gui.popup_template")
local combinator_schedule = require("gui.combinator_schedule")

local drone_count_popup = {}

function drone_count_popup.open(player, unit_number, group_id)
    local data = global.combinator_areas[unit_number]
    if not data then return end
    local group = nil
    for _, g in ipairs(data.groups) do
        if g.id == group_id then
            group = g
            break
        end
    end
    if not group then return end

    local title = "Количество дронов для группы \"" .. (group.name or "Без имени") .. "\""
    local current_logistic = group.logistic or 0
    local current_construction = group.construction or 0

    popup_template.open(player, title, function(content_flow, params, frame, popup_name)
        -- Таблица для двух типов дронов
        local grid = content_flow.add({ type = "table", column_count = 2 })
        grid.style.width = 400
        grid.style.horizontal_spacing = 12
        grid.style.vertical_spacing = 10
        grid.style.cell_padding = 0

        -- Логистические дроны
        local logistic_label = grid.add({ type = "label", caption = "Логистические дроны:", style = "bold_label" })
        logistic_label.style.width = 160

        local logistic_flow = grid.add({ type = "flow", direction = "horizontal" })
        logistic_flow.style.horizontal_spacing = 8
        logistic_flow.style.vertical_align = "center"

        local logistic_slider = logistic_flow.add({
            type = "slider",
            name = "drone_slider_" .. unit_number .. "_" .. group_id .. "_logistic",
            minimum_value = 0,
            maximum_value = 500,
            value_step = 50,
            value = current_logistic,
            style = "notched_slider"
        })
        logistic_slider.style.width = 180

        local logistic_text = logistic_flow.add({
            type = "textfield",
            name = "drone_text_" .. unit_number .. "_" .. group_id .. "_logistic",
            text = tostring(current_logistic),
            numeric = true,
            style = "textbox"
        })
        logistic_text.style.width = 60

        -- Строительные дроны
        local construction_label = grid.add({ type = "label", caption = "Строительные дроны:", style = "bold_label" })
        construction_label.style.width = 160

        local construction_flow = grid.add({ type = "flow", direction = "horizontal" })
        construction_flow.style.horizontal_spacing = 8
        construction_flow.style.vertical_align = "center"

        local construction_slider = construction_flow.add({
            type = "slider",
            name = "drone_slider_" .. unit_number .. "_" .. group_id .. "_construction",
            minimum_value = 0,
            maximum_value = 500,
            value_step = 50,
            value = current_construction,
            style = "notched_slider"
        })
        construction_slider.style.width = 180

        local construction_text = construction_flow.add({
            type = "textfield",
            name = "drone_text_" .. unit_number .. "_" .. group_id .. "_construction",
            text = tostring(current_construction),
            numeric = true,
            style = "textbox"
        })
        construction_text.style.width = 60

        -- Кнопка Сохранить
        local button_flow = content_flow.add({ type = "flow", direction = "horizontal" })
        button_flow.style.horizontal_align = "center"
        button_flow.style.top_margin = 16

        local save_btn = button_flow.add({
            type = "button",
            name = "drone_save_button_" .. unit_number .. "_" .. group_id,
            caption = "Сохранить",
            style = "confirm_button",
            tags = { unit_number = unit_number, group_id = group_id, popup_name = popup_name }
        })
        save_btn.style.width = 120
        save_btn.style.height = 32
        save_btn.style.font = "default-bold"

    end, { unit_number = unit_number, group_id = group_id }, 450) -- ширина 450
end

return drone_count_popup