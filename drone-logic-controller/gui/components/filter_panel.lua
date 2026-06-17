-- gui/components/filter_panel.lua
local task_block = require("gui/components/task_block")

local filter_panel = {}

local DEFAULT_CHEST_ORDER = {
    "active-provider-chest",
    "passive-provider-chest",
    "storage-chest",
    "buffer-chest",
    "requester-chest",
}

local CHEST_NAMES = {
    ["active-provider-chest"] = "Задачи активного снабжения",
    ["passive-provider-chest"] = "Задачи пасивного снабжения",
    ["storage-chest"] = "Задачи хранения",
    ["buffer-chest"] = "Буферные задачи",
    ["requester-chest"] = "Задачи запросов",
}

function filter_panel.build_filter_panel(parent, pending, player_index)
    parent.clear()

    if not pending.filter_order then
        pending.filter_order = {}
        for _, ct in ipairs(DEFAULT_CHEST_ORDER) do
            table.insert(pending.filter_order, ct)
        end
    end

    -- Инициализация filter_group_enabled, если нет
    if not pending.filter_group_enabled then
        pending.filter_group_enabled = {}
        for _, ct in ipairs(DEFAULT_CHEST_ORDER) do
            pending.filter_group_enabled[ct] = true
        end
    end

    -- Общий заголовок "Фильтры" с кнопкой для окна чекбоксов
    local header_flow = parent.add{
        type = "flow",
        direction = "horizontal",
        name = "filter_panel_header"
    }
    header_flow.style.width = 384
    header_flow.style.horizontally_stretchable = false
    header_flow.style.vertical_align = "center"
    header_flow.style.bottom_margin = 4

    header_flow.add{
        type = "label",
        caption = "Фильтры",
        style = "caption_label"
    }
    local spacer_header = header_flow.add{
        type = "empty-widget"
    }
    spacer_header.style.horizontally_stretchable = true
    spacer_header.style.width = 0

    local filter_button = header_flow.add{
        type = "button",
        name = "filter_visibility_button",
        caption = "⚙",
        style = "tool_button",
        tooltip = "Настроить видимость категорий"
    }
    filter_button.style.width = 24
    filter_button.style.height = 24
    filter_button.style.padding = 0
    filter_button.style.margin = 0
    filter_button.tags = { player_index = player_index }

    -- Группы по сохранённому порядку
    local grid_states = pending.grid_states
    local active_tasks = {}
    for _, task in ipairs(pending.tasks) do
        local row, col = task.grid_row, task.grid_col
        if row and col and grid_states[row] and grid_states[row][col] then
            table.insert(active_tasks, task)
        end
    end

    for _, chest_type in ipairs(pending.filter_order) do
        local tasks_of_type = {}
        for _, task in ipairs(active_tasks) do
            if task.chest_type == chest_type then
                table.insert(tasks_of_type, task)
            end
        end

        -- Пропускаем скрытые группы (через чекбоксы)
        if pending.filter_visibility[chest_type] == false then
            goto continue
        end

        local group_flow = parent.add{
            type = "flow",
            direction = "vertical",
            name = "filter_group_flow_" .. chest_type
        }
        group_flow.style.width = 384
        group_flow.style.horizontally_stretchable = false
        group_flow.style.vertical_spacing = 4
        group_flow.style.padding = 0
        group_flow.style.margin = {0, 0, 4, 0}

        -- Видимый заголовок
        local header_frame = group_flow.add{
            type = "frame",
            name = "filter_header_frame_" .. chest_type,
            style = "bordered_frame"
        }
        header_frame.style.width = 384
        header_frame.style.height = 40
        header_frame.style.horizontally_stretchable = false
        header_frame.style.padding = 6

        local header_flow2 = header_frame.add{
            type = "flow",
            direction = "horizontal",
            name = "filter_header_flow_" .. chest_type
        }
        header_flow2.style.vertical_align = "center"
        header_flow2.style.horizontal_spacing = 6
        header_flow2.style.horizontally_stretchable = true
        header_flow2.style.height = 28

        local name_label = header_flow2.add{
            type = "label",
            caption = CHEST_NAMES[chest_type] or chest_type,
            style = "bold_label"
        }
        name_label.style.maximal_width = 230
        name_label.style.single_line = true
        name_label.style.font = "default-semibold"
        name_label.style.font_color = {1, 1, 1}

        local spacer = header_flow2.add{
            type = "empty-widget"
        }
        spacer.style.horizontally_stretchable = true
        spacer.style.width = 0

        -- Кнопки управления (перемещение + остановка)
        local buttons_flow = header_flow2.add{
            type = "flow",
            direction = "horizontal",
            name = "filter_header_buttons_" .. chest_type
        }
        buttons_flow.style.horizontal_spacing = 1
        buttons_flow.style.vertical_align = "center"
        buttons_flow.style.horizontally_stretchable = false

        local up_btn = buttons_flow.add{
            type = "button",
            name = "filter_group_move_up_" .. chest_type,
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
            player_index = player_index,
            chest_type = chest_type
        }

        local down_btn = buttons_flow.add{
            type = "button",
            name = "filter_group_move_down_" .. chest_type,
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
            player_index = player_index,
            chest_type = chest_type
        }

        -- Кнопка остановки/запуска группы (включает/отключает задачи)
        local group_enabled = pending.filter_group_enabled[chest_type] ~= false
        local toggle_sprite = group_enabled and "utility/play" or "utility/stop"
        local toggle_btn = buttons_flow.add{
            type = "sprite-button",
            name = "filter_group_toggle_" .. chest_type,
            sprite = toggle_sprite,
            style = "tool_button",
            tooltip = group_enabled and "Группа активна" or "Группа остановлена"
        }
        toggle_btn.style.width = 24
        toggle_btn.style.height = 24
        toggle_btn.style.padding = 0
        toggle_btn.style.margin = 0
        toggle_btn.tags = {
            player_index = player_index,
            chest_type = chest_type
        }

        -- Контейнер задач
        local tasks_flow = group_flow.add{
            type = "flow",
            direction = "vertical",
            name = "filter_tasks_" .. chest_type
        }
        tasks_flow.style.width = 384
        tasks_flow.style.horizontal_align = "right"
        tasks_flow.style.vertical_spacing = 2
        tasks_flow.style.padding = {0, 4, 0, 0}

        table.sort(tasks_of_type, function(a,b) return a.display_order < b.display_order end)
        for _, task in ipairs(tasks_of_type) do
            task_block.create_task_block(tasks_flow, task, player_index, {show_move_buttons = true})
        end
        if #tasks_of_type == 0 then
            tasks_flow.add{type="label", caption="Нет задач", style="label"}
        end

        ::continue::
    end
end

return filter_panel