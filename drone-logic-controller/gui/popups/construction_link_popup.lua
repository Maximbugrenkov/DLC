-- gui/popups/construction_link_popup.lua
local popup_template = require("gui.popup_template")

local construction_link_popup = {}

function construction_link_popup.open(player, unit_number, group_id, area_id, item_id)
    local data = global.combinator_areas[unit_number]
    if not data then return end
    local area = nil
    for _, a in ipairs(data.areas[group_id] or {}) do
        if a.id == area_id then
            area = a
            break
        end
    end
    if not area or not area.construction_data then return end
    local link = nil
    for _, l in ipairs(area.construction_data.links or {}) do
        if l.id == item_id then
            link = l
            break
        end
    end
    if not link then return end

    local title = string.format("Настройка строительной связи: %s", link.name or "Без имени")

    -- Сохраняем текущий выбранный режим и данные
    local use_current = (link.use_current_area == true)
    local current_global_area_id = area.global_area_id
    local currently_selected_areas = link.areas or {}

    popup_template.open(player, title, function(content_flow, params, frame, popup_name)
        -- Радиокнопки выбора режима
        local mode_flow = content_flow.add({ type = "flow", direction = "horizontal" })
        mode_flow.style.horizontal_spacing = 16
        mode_flow.style.bottom_margin = 12

        local radio_current = mode_flow.add({
            type = "radiobutton",
            name = popup_name .. "_mode_current",
            caption = "Текущая область",
            state = use_current,
            tags = { mode = "current", popup_name = popup_name }
        })
        local radio_multi = mode_flow.add({
            type = "radiobutton",
            name = popup_name .. "_mode_multi",
            caption = "Связанная область",
            state = not use_current,
            tags = { mode = "multi", popup_name = popup_name }
        })

        -- Блок для режима "Текущая область" (информационная строка)
        local current_block = content_flow.add({ type = "flow", direction = "vertical", name = popup_name .. "_current_block" })
        current_block.style.bottom_margin = 8
        if current_global_area_id and global.areas[current_global_area_id] then
            current_block.add({ type = "label", caption = "Будет связана с зоной: " .. global.areas[current_global_area_id].name, style = "bold_label" })
        else
            current_block.add({ type = "label", caption = "Текущая область не имеет глобальной зоны.", style = "bold_label" })
        end
        current_block.visible = use_current

        -- Блок для режима "Несколько областей" (список с галочками)
        local multi_block = content_flow.add({ type = "flow", direction = "vertical", name = popup_name .. "_multi_block" })
        multi_block.visible = not use_current

        local scroll = multi_block.add({ type = "scroll-pane", style = "naked_scroll_pane" })
        scroll.style.height = 300
        scroll.style.width = 380
        local list = scroll.add({ type = "flow", direction = "vertical" })
        list.style.width = 360
        list.style.vertical_spacing = 4

        local areas_list = {}
        for id, zone in pairs(global.areas or {}) do
            table.insert(areas_list, { id = id, name = zone.name })
        end
        table.sort(areas_list, function(a,b) return a.name < b.name end)

        if #areas_list == 0 then
            list.add({ type = "label", caption = "Нет созданных зон. Сначала создайте зону через планировщик." })
        else
            for _, zone_info in ipairs(areas_list) do
                local is_checked = false
                for _, selected_id in ipairs(currently_selected_areas) do
                    if selected_id == zone_info.id then
                        is_checked = true
                        break
                    end
                end
                local cb = list.add({
                    type = "checkbox",
                    name = "link_area_cb_" .. zone_info.id,
                    caption = zone_info.name,
                    state = is_checked,
                    tags = { area_id = zone_info.id }
                })
                cb.style.width = 340
            end
        end

        -- Кнопки Сохранить / Отмена
        local btn_flow = content_flow.add({ type = "flow", direction = "horizontal", top_margin = 16 })
        btn_flow.style.horizontal_align = "center"

        local save_btn = btn_flow.add({
            type = "button",
            caption = "Сохранить",
            style = "confirm_button",
            tags = {
                unit_number = unit_number,
                group_id = group_id,
                area_id = area_id,
                item_id = item_id,
                popup_name = popup_name,
                kind = "construction_link"
            }
        })
        save_btn.style.width = 100

        local cancel_btn = btn_flow.add({
            type = "button",
            caption = "Отмена",
            style = "back_button",
            tags = { popup_name = popup_name }
        })
        cancel_btn.style.width = 80

        -- Сохраняем ссылки на элементы в frame.tags для доступа при обновлении видимости
        frame.tags = {
            popup_name = popup_name,
            radio_current = radio_current,
            radio_multi = radio_multi,
            current_block = current_block,
            multi_block = multi_block
        }
    end, nil, 420)
end

return construction_link_popup