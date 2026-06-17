-- gui/popups/area_drone_popup.lua
local popup_template = require("gui.popup_template")
local combinator_schedule = require("gui.combinator_schedule")

local area_drone_popup = {}

function area_drone_popup.open(player, unit_number, group_id, area_id, kind)
    local data = global.combinator_areas[unit_number]
    if not data then return end
    local area = nil
    for _, a in ipairs(data.areas[group_id] or {}) do
        if a.id == area_id then
            area = a
            break
        end
    end
    if not area then return end

    local section = (kind == "logistic") and area.logistic_data or area.construction_data
    local current_value = section.drone_count or 0
    local is_manual = (kind == "logistic" and area.manual_logistic) or (kind == "construction" and area.manual_construction)
    local auto_distribute_tasks = (section.auto_distribute_tasks ~= false)  -- по умолчанию true

    local title = string.format("Настройка дронов для области \"%s\" (%s)", area.name or "Без имени", (kind == "logistic") and "логистические" or "строительные")

    popup_template.open(player, title, function(content_flow, params, frame, popup_name)
        local flow = content_flow.add({ type = "flow", direction = "vertical" })
        flow.style.vertical_spacing = 8

        flow.add({ type = "label", caption = "Количество дронов:", style = "bold_label" })

        local slider_flow = flow.add({ type = "flow", direction = "horizontal" })
        slider_flow.style.horizontal_spacing = 8
        slider_flow.style.vertical_align = "center"

        local slider = slider_flow.add({
            type = "slider",
            name = "area_drone_slider",
            minimum_value = 0,
            maximum_value = 500,
            value_step = 10,
            value = current_value,
            style = "notched_slider"
        })
        slider.style.width = 180

        local textfield = slider_flow.add({
            type = "textfield",
            name = "area_drone_text",
            text = tostring(current_value),
            numeric = true,
            style = "textbox"
        })
        textfield.style.width = 60

        -- Чекбокс "Автоматически" (сброс ручной настройки для области)
        local auto_checkbox = flow.add({
            type = "checkbox",
            name = "area_drone_auto",
            caption = "Автоматически распределять (по умолчанию)",
            state = not is_manual
        })
        auto_checkbox.style.top_margin = 8

        -- НОВЫЙ ЧЕКБОКС: автоматическое распределение по задачам и связям
        local auto_tasks_checkbox = flow.add({
            type = "checkbox",
            name = "area_drone_auto_tasks",
            caption = "Автоматически распределять по задачам и связям",
            state = auto_distribute_tasks
        })
        auto_tasks_checkbox.style.top_margin = 4

        local button_flow = flow.add({ type = "flow", direction = "horizontal" })
        button_flow.style.horizontal_align = "center"
        button_flow.style.top_margin = 16

        local save_btn = button_flow.add({
            type = "button",
            name = "area_drone_save",
            caption = "Сохранить",
            style = "confirm_button",
            tags = { unit_number = unit_number, group_id = group_id, area_id = area_id, kind = kind, popup_name = popup_name }
        })
        save_btn.style.width = 100
    end, { unit_number = unit_number, group_id = group_id, area_id = area_id, kind = kind }, 400)
end

return area_drone_popup