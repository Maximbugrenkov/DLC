-- gui/components/group_block.lua
local task_block = require("gui/components/task_block")

local group_block = {}

function group_block.create_group_block(parent, group_data, player_index, pending)
    local player = game.players[player_index]
    if not player then return end

    -- default enabled = true
    if group_data.enabled == nil then
        group_data.enabled = true
    end

    local group_flow = parent.add{
        type = "flow",
        direction = "vertical",
        name = "group_flow_" .. group_data.id
    }
    group_flow.style.width = 384
    group_flow.style.horizontally_stretchable = false
    group_flow.style.vertical_spacing = 4
    group_flow.style.padding = 0
    group_flow.style.margin = {0, 0, 4, 0}

    -- Заголовок группы
    local header_frame = group_flow.add{
        type = "frame",
        name = "group_header_frame_" .. group_data.id,
        style = "bordered_frame"
    }
    header_frame.style.width = 384
    header_frame.style.height = 40
    header_frame.style.horizontally_stretchable = false
    header_frame.style.padding = 6

    local header_flow = header_frame.add{
        type = "flow",
        direction = "horizontal",
        name = "group_header_" .. group_data.id
    }
    header_flow.style.vertical_align = "center"
    header_flow.style.horizontal_spacing = 6
    header_flow.style.horizontally_stretchable = true
    header_flow.style.height = 28

    local left_flow = header_flow.add{
        type = "flow",
        direction = "horizontal",
        name = "group_left_flow_" .. group_data.id
    }
    left_flow.style.horizontal_spacing = 4
    left_flow.style.vertical_align = "center"
    left_flow.style.horizontally_stretchable = false

    local name_label = left_flow.add{
        type = "label",
        name = "group_name_label_" .. group_data.id,
        caption = group_data.name or "Новая группа",
        style = "bold_label"
    }
    name_label.style.maximal_width = 200
    name_label.style.single_line = true
    name_label.style.font = "default-semibold"
    name_label.style.font_color = {1, 1, 1}
    name_label.visible = true

    local name_field = left_flow.add{
        type = "textfield",
        name = "group_name_field_" .. group_data.id,
        text = group_data.name or "Новая группа",
        style = "textbox",
        visible = false
    }
    name_field.style.minimal_width = 200
    name_field.style.height = 28
    name_field.style.font = "default-semibold"
    name_field.tags = {
        group_id = group_data.id,
        player_index = player_index
    }

    global.group_name_labels = global.group_name_labels or {}
    global.group_name_textfields = global.group_name_textfields or {}
    global.group_name_labels[group_data.id] = name_label
    global.group_name_textfields[group_data.id] = name_field

    local spacer = header_flow.add{
        type = "empty-widget",
        name = "group_header_spacer_" .. group_data.id
    }
    spacer.style.horizontally_stretchable = true
    spacer.style.height = 1
    spacer.style.width = 0

    local right_flow = header_flow.add{
        type = "flow",
        direction = "horizontal",
        name = "group_right_flow_" .. group_data.id
    }
    -- ← ИСПРАВЛЕНИЕ: ставим такой же отступ, как в task_block (1px)
    right_flow.style.horizontal_spacing = 1
    right_flow.style.vertical_align = "center"
    right_flow.style.horizontally_stretchable = false

    -- Кнопка редактирования имени
    local edit_btn = right_flow.add{
        type = "sprite-button",
        name = "group_edit_name_button_" .. group_data.id,
        sprite = "utility/rename_icon",
        style = "tool_button",
        tooltip = "Редактировать имя группы"
    }
    edit_btn.style.width = 24
    edit_btn.style.height = 24
    edit_btn.style.padding = 0
    edit_btn.style.margin = 0
    edit_btn.tags = {
        group_id = group_data.id,
        player_index = player_index
    }

    -- Кнопка перемещения вверх
    local up_btn = right_flow.add{
        type = "button",
        name = "group_move_up_" .. group_data.id,
        caption = "▲",
        style = "tool_button",
        tooltip = "Переместить группу вверх"
    }
    up_btn.style.width = 24
    up_btn.style.height = 24
    up_btn.style.font = "default-bold"
    up_btn.style.padding = 0
    up_btn.style.margin = 0
    up_btn.tags = {
        group_id = group_data.id,
        player_index = player_index,
        direction = "up"
    }

    -- Кнопка перемещения вниз
    local down_btn = right_flow.add{
        type = "button",
        name = "group_move_down_" .. group_data.id,
        caption = "▼",
        style = "tool_button",
        tooltip = "Переместить группу вниз"
    }
    down_btn.style.width = 24
    down_btn.style.height = 24
    down_btn.style.font = "default-bold"
    down_btn.style.padding = 0
    down_btn.style.margin = 0
    down_btn.tags = {
        group_id = group_data.id,
        player_index = player_index,
        direction = "down"
    }

    -- Кнопка остановки/запуска группы (toggle)
    local toggle_sprite = group_data.enabled and "utility/play" or "utility/stop"
    local toggle_btn = right_flow.add{
        type = "sprite-button",
        name = "group_toggle_button_" .. group_data.id,
        sprite = toggle_sprite,
        style = "tool_button",
        tooltip = group_data.enabled and "Группа активна" or "Группа остановлена"
    }
    toggle_btn.style.width = 24
    toggle_btn.style.height = 24
    toggle_btn.style.padding = 0
    toggle_btn.style.margin = 0
    toggle_btn.tags = {
        group_id = group_data.id,
        player_index = player_index
    }

    -- Кнопка удаления группы
    local delete_btn = right_flow.add{
        type = "sprite-button",
        name = "group_delete_button_" .. group_data.id,
        sprite = "utility/trash",
        style = "tool_button_red",
        tooltip = "Удалить группу"
    }
    delete_btn.style.width = 24
    delete_btn.style.height = 24
    delete_btn.style.padding = 0
    delete_btn.style.margin = 0
    delete_btn.tags = {
        group_id = group_data.id,
        player_index = player_index
    }

    -- Контейнер для задач группы
    local tasks_container = group_flow.add{
        type = "flow",
        direction = "vertical",
        name = "group_tasks_container_" .. group_data.id
    }
    tasks_container.style.width = 384
    tasks_container.style.horizontally_stretchable = false
    tasks_container.style.vertical_spacing = 2
    tasks_container.style.padding = 0
    tasks_container.style.horizontal_align = "right"

    local grid_states = pending.grid_states
    for _, task in ipairs(pending.tasks) do
        if task.group_id == group_data.id then
            local row, col = task.grid_row, task.grid_col
            if row and col and grid_states[row] and grid_states[row][col] then
                task_block.create_task_block(tasks_container, task, player_index, {
                    show_move_buttons = true,
                    show_group_remove_button = true
                })
            end
        end
    end

    -- Кнопка «Добавить задачу»
    local add_flow = group_flow.add{
        type = "flow",
        direction = "horizontal",
        name = "group_add_flow_" .. group_data.id
    }
    add_flow.style.horizontal_align = "right"
    add_flow.style.width = 384
    add_flow.style.horizontally_stretchable = false

    local add_task_btn = add_flow.add{
        type = "button",
        name = "group_add_task_button_" .. group_data.id,
        caption = "+ Добавить задачу",
        style = "button"
    }
    add_task_btn.style.width = 300
    add_task_btn.style.height = 38
    add_task_btn.style.horizontal_align = "left"
    add_task_btn.style.left_padding = 8
    add_task_btn.tags = {
        group_id = group_data.id,
        player_index = player_index
    }

    return group_flow
end

return group_block