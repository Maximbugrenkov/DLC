-- gui/popups/task_drone_popup.lua
local popup_template = require("gui.popup_template")
local combinator_schedule = require("gui.combinator_schedule")

local task_drone_popup = {}

function task_drone_popup.open(player, unit_number, group_id, area_id, section_kind, item_kind, item_id)
    local data = global.combinator_areas[unit_number]
    if not data then return end
    local area = nil
    for _, a in ipairs(data.areas[group_id] or {}) do
        if a.id == area_id then area = a; break end
    end
    if not area then return end
    local section = (section_kind == "construction") and area.construction_data or area.logistic_data
    if not section then return end
    if section.auto_distribute_tasks then
        player.print("Автоматическое распределение включено. Отключите его в настройках области.")
        return
    end
    local items = (item_kind == "task") and section.tasks or section.links
    local item = nil
    for _, it in ipairs(items) do
        if it.id == item_id then item = it; break end
    end
    if not item then return end

    -- Вычисляем максимальное доступное количество с учётом уже занятых другими
    local used_others = 0
    for _, it in ipairs(items) do
        if it.id ~= item_id then
            used_others = used_others + (it.drone_count or 0)
        end
    end
    local max_allowed = (section.drone_count or 0) - used_others
    if max_allowed < 0 then max_allowed = 0 end
    local current_value = math.min(item.drone_count or 0, max_allowed)

    local title = string.format("Настройка %s: \"%s\"", (item_kind == "task") and "задачи" or "связи", item.name)

    popup_template.open(player, title, function(content_flow, params, frame, popup_name)
        local flow = content_flow.add({ type = "flow", direction = "vertical" })
        flow.style.vertical_spacing = 8

        flow.add({ type = "label", caption = "Количество дронов:", style = "bold_label" })
        flow.add({ type = "label", caption = "Доступно: " .. max_allowed, style = "caption_label" })

        local slider_flow = flow.add({ type = "flow", direction = "horizontal" })
        slider_flow.style.horizontal_spacing = 8
        slider_flow.style.vertical_align = "center"

        local slider = slider_flow.add({
            type = "slider",
            name = "task_drone_slider",
            minimum_value = 0,
            maximum_value = max_allowed,
            value_step = 1,
            value = current_value,
            style = "notched_slider"
        })
        slider.style.width = 180

        local textfield = slider_flow.add({
            type = "textfield",
            name = "task_drone_text",
            text = tostring(current_value),
            numeric = true,
            style = "textbox"
        })
        textfield.style.width = 60

        local button_flow = flow.add({ type = "flow", direction = "horizontal" })
        button_flow.style.horizontal_align = "center"
        button_flow.style.top_margin = 16

        local save_btn = button_flow.add({
            type = "button",
            name = "task_drone_save",
            caption = "Сохранить",
            style = "confirm_button",
            tags = {
                unit_number = unit_number,
                group_id = group_id,
                area_id = area_id,
                section_kind = section_kind,
                item_kind = item_kind,
                item_id = item_id,
                popup_name = popup_name
            }
        })
        save_btn.style.width = 100
    end, { unit_number = unit_number, group_id = group_id, area_id = area_id, section_kind = section_kind, item_kind = item_kind, item_id = item_id }, 350)
end

return task_drone_popup