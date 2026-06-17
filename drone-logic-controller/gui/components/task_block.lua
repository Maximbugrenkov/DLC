-- gui/components/task_block.lua
local task_utils = require("utils/task_utils")

local task_block = {}

function task_block.create_task_block(parent, task_data, player_index, options)
    -- Защита от отсутствия task_id
    if not task_data or not task_data.task_id then
        log("Ошибка: попытка создать task_block без task_id")
        return nil
    end

    local player = game.players[player_index]
    if not player then return end

    options = options or {}

    local block_frame = parent.add{
        type = "frame",
        name = "task_block_" .. task_data.task_id,
        style = "bordered_frame"
    }
    block_frame.style.width = 300
    block_frame.style.height = 38
    block_frame.style.horizontally_stretchable = false
    block_frame.style.vertically_stretchable = false
    block_frame.style.padding = {0, 2, 0, 2}
    block_frame.style.margin = 0
    block_frame.style.vertical_align = "center"

    local content_flow = block_frame.add{
        type = "flow",
        direction = "horizontal",
        name = "task_content_flow_" .. task_data.task_id
    }
    content_flow.style.vertical_align = "center"
    content_flow.style.horizontal_spacing = 2
    content_flow.style.horizontally_stretchable = true
    content_flow.style.vertically_stretchable = false

    -- Левая часть: иконка, статус, название
    local left_flow = content_flow.add{
        type = "flow",
        direction = "horizontal",
        name = "task_left_flow_" .. task_data.task_id
    }
    left_flow.style.horizontal_spacing = 2
    left_flow.style.vertical_align = "center"
    left_flow.style.horizontally_stretchable = false

    -- Иконка сундука
    local icon = left_flow.add{
        type = "sprite-button",
        style = "slot_button",
        sprite = "entity/" .. task_data.chest_type,
        enabled = true,
        name = "task_open_button_" .. task_data.task_id
    }
    icon.style.width = 24
    icon.style.height = 24
    icon.style.padding = 0
    icon.style.margin = 0
    icon.tooltip = "Открыть " .. task_data.chest_type
    icon.tags = {
        task_id = task_data.task_id,
        player_index = player_index,
        chest_type = task_data.chest_type,
        position = task_data.position
    }

    -- Кнопка статуса
    local status_btn = left_flow.add{
        type = "sprite-button",
        name = "task_status_button_" .. task_data.task_id,
        sprite = "utility/status_yellow",
        style = "tool_button",
        tooltip = "Показать статус"
    }
    status_btn.style.width = 24
    status_btn.style.height = 24
    status_btn.style.padding = 0
    status_btn.style.margin = 0
    status_btn.tags = {
        task_id = task_data.task_id,
        player_index = player_index,
        chest_type = task_data.chest_type,
        position = task_data.position
    }

    -- Имя задачи
    local entity = game.surfaces[1].find_entities_filtered{
        name = task_data.chest_type,
        position = task_data.position,
        limit = 1
    }[1]

    local display_name
    if task_data.custom_name then
        display_name = task_data.custom_name
    elseif entity and entity.valid then
        display_name = entity.localised_name
    else
        display_name = task_data.chest_type
    end

    local name_label = left_flow.add{
        type = "label",
        name = "task_name_label_" .. task_data.task_id,
        caption = display_name,
        style = "label"
    }
    name_label.style.horizontally_stretchable = false
    if options.show_group_remove_button then
        name_label.style.maximal_width = 110
    else
        name_label.style.maximal_width = 140
    end
    name_label.style.height = 24
    name_label.style.font = "default-semibold"
    name_label.style.single_line = true
    name_label.style.font_color = {1, 1, 1}
    name_label.tooltip = (entity and entity.valid) and entity.name or task_data.chest_type
    name_label.visible = true

    -- Текстовое поле для редактирования
    local name_field = left_flow.add{
        type = "textfield",
        name = "task_name_field_" .. task_data.task_id,
        text = task_data.custom_name or "",
        style = "textbox",
        visible = false
    }
    name_field.style.horizontally_stretchable = false
    name_field.style.minimal_width = 80
    name_field.style.height = 24
    name_field.style.font = "default-semibold"
    name_field.tags = {
        task_id = task_data.task_id,
        player_index = player_index
    }

    global.task_name_labels = global.task_name_labels or {}
    global.task_name_textfields = global.task_name_textfields or {}
    global.task_name_labels[task_data.task_id] = name_label
    global.task_name_textfields[task_data.task_id] = name_field

    -- Растягивающийся разделитель
    local spacer = content_flow.add{
        type = "empty-widget",
        name = "task_spacer_" .. task_data.task_id
    }
    spacer.style.horizontally_stretchable = true
    spacer.style.vertically_stretchable = false
    spacer.style.height = 1
    spacer.style.width = 0

    -- Правая часть: кнопки управления
    local right_flow = content_flow.add{
        type = "flow",
        direction = "horizontal",
        name = "task_right_flow_" .. task_data.task_id
    }
    right_flow.style.horizontal_spacing = 1
    right_flow.style.vertical_align = "center"
    right_flow.style.horizontally_stretchable = false

    -- Кнопка переименования
    local edit_btn = right_flow.add{
        type = "sprite-button",
        name = "task_edit_name_button_" .. task_data.task_id,
        sprite = "utility/rename_icon",
        style = "tool_button",
        tooltip = "Редактировать имя"
    }
    edit_btn.style.width = 24
    edit_btn.style.height = 24
    edit_btn.style.padding = 0
    edit_btn.style.margin = 0
    edit_btn.tags = {
        task_id = task_data.task_id,
        player_index = player_index
    }

    -- Кнопки перемещения
    if options.show_move_buttons then
        local up_btn = right_flow.add{
            type = "button",
            name = "task_move_up_" .. task_data.task_id,
            caption = "▲",
            style = "tool_button",
            tooltip = "Переместить вверх"
        }
        up_btn.style.width = 24
        up_btn.style.height = 24
        up_btn.style.font = "default-bold"
        up_btn.style.padding = 0
        up_btn.style.margin = 0
        up_btn.tags = {
            task_id = task_data.task_id,
            player_index = player_index,
            direction = "up"
        }

        local down_btn = right_flow.add{
            type = "button",
            name = "task_move_down_" .. task_data.task_id,
            caption = "▼",
            style = "tool_button",
            tooltip = "Переместить вниз"
        }
        down_btn.style.width = 24
        down_btn.style.height = 24
        down_btn.style.font = "default-bold"
        down_btn.style.padding = 0
        down_btn.style.margin = 0
        down_btn.tags = {
            task_id = task_data.task_id,
            player_index = player_index,
            direction = "down"
        }
    end

    -- Кнопка включения/выключения задачи
    local toggle_sprite = task_data.enabled and "utility/play" or "utility/stop"
    local toggle_btn = right_flow.add{
        type = "sprite-button",
        name = "task_toggle_button_" .. task_data.task_id,
        sprite = toggle_sprite,
        style = "tool_button",
        tooltip = task_data.enabled and "Задача активна" or "Задача отключена"
    }
    toggle_btn.style.width = 24
    toggle_btn.style.height = 24
    toggle_btn.style.padding = 0
    toggle_btn.style.margin = 0
    toggle_btn.tags = {
        task_id = task_data.task_id,
        player_index = player_index
    }

    -- Кнопка удаления из группы
    if options.show_group_remove_button and task_data.group_id then
        local remove_btn = right_flow.add{
            type = "sprite-button",
            name = "group_remove_task_button_" .. task_data.task_id,
            sprite = "utility/trash",
            style = "tool_button_red",
            tooltip = "Убрать из группы"
        }
        remove_btn.style.width = 24
        remove_btn.style.height = 24
        remove_btn.style.padding = 0
        remove_btn.style.margin = 0
        remove_btn.tags = {
            task_id = task_data.task_id,
            group_id = task_data.group_id,
            player_index = player_index
        }
    end

    return block_frame
end

return task_block