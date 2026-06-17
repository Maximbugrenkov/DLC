-- gui/area_editor.lua
local task_block = require("gui/components/task_block")
local task_utils = require("utils/task_utils")
local filter_panel = require("gui/components/filter_panel")
local group_block = require("gui/components/group_block")

local area_editor = {}

-- Вспомогательная функция get_cell_sprite (без изменений)
local function get_cell_sprite(row, col, pending, state)
    local chest_type = nil
    if pending and pending.logistic_chests then
        for _, chest in ipairs(pending.logistic_chests) do
            if chest.grid_row == row and chest.grid_col == col then
                chest_type = chest.type
                break
            end
        end
    end

    if not chest_type then
        return state and "dlc_cell_blue" or "dlc_cell_gray"
    end

    local suffix_map = {
        ["active-provider-chest"] = "active_provider",
        ["passive-provider-chest"] = "passive_provider",
        ["storage-chest"] = "storage",
        ["buffer-chest"] = "buffer",
        ["requester-chest"] = "requester",
    }
    local suffix = suffix_map[chest_type] or "active_provider"

    if state then
        return "dlc_cell_blue_" .. suffix
    else
        return "dlc_cell_gray_" .. suffix
    end
end

local function get_chest_info(entity) return "" end
local function refresh_tasks_frame_only(frame, player_index) end

local function refresh_components_frame_only(frame, player_index)
    local player = game.players[player_index]
    local pending = global.pending_areas[player_index]
    if not pending then return end

    local content_flow = frame.content_flow
    if not content_flow then return end
    local main_content_flow = content_flow.main_content_flow
    if not main_content_flow then return end
    local left_panel = main_content_flow.left_panel
    if not left_panel then return end
    local left_vertical_flow = left_panel.left_vertical_flow
    if not left_vertical_flow then return end
    local scroll_pane = left_vertical_flow.left_scroll_pane
    if not scroll_pane then return end
    local vertical_flow = scroll_pane.left_vertical_flow_content
    if not vertical_flow then return end

    local frame2 = vertical_flow.dlc_frame_2
    if not frame2 or not frame2.valid then return end

    local frame2_vertical = frame2.children[1]
    if not frame2_vertical or frame2_vertical.type ~= "flow" then return end

    local slots_panel = frame2_vertical.components_slots_frame
    if not slots_panel then return end
    local components_table = slots_panel.components_table
    if not components_table then return end

    components_table.clear()

    local surface = player.surface
    local min_x, min_y = pending.min_x, pending.min_y
    local width, height = pending.width, pending.height
    local grid_states = pending.grid_states

    local entity_counts = {}
    for row = 1, height do
        for col = 1, width do
            if grid_states[row] and grid_states[row][col] then
                local world_x = min_x + (col - 1)
                local world_y = min_y + (row - 1)
                local entities = surface.find_entities_filtered{
                    area = {{world_x, world_y}, {world_x + 1, world_y + 1}}
                }
                for _, entity in pairs(entities) do
                    local name = entity.name
                    entity_counts[name] = (entity_counts[name] or 0) + 1
                end
            end
        end
    end

    local objects_list = {}
    for name, count in pairs(entity_counts) do
        local sample_entity = surface.find_entities_filtered{name = name, limit = 1}[1]
        local localised_name = sample_entity and sample_entity.localised_name or name
        table.insert(objects_list, {
            name = name,
            count = count,
            localised_name = localised_name
        })
    end

    local count = #objects_list
    for idx = 1, math.max(count, 1) do
        local elem_button = components_table.add{
            type = "choose-elem-button",
            name = "component_slot_" .. idx,
            elem_type = "entity",
            style = "slot_button"
        }
        elem_button.style.width = 36
        elem_button.style.height = 36
        elem_button.style.horizontally_stretchable = false
        elem_button.style.vertically_stretchable = false
        elem_button.style.padding = 0
        elem_button.style.margin = 0
        elem_button.enabled = false

        if idx <= count then
            local obj = objects_list[idx]
            elem_button.elem_value = obj.name
            if obj.count > 1 then
                elem_button.tooltip = {"", obj.localised_name, " (", obj.count, ")"}
            else
                elem_button.tooltip = obj.localised_name
            end
        else
            elem_button.elem_value = nil
            elem_button.tooltip = ""
        end
    end
end

-- Функция перестроения панели «Все»
local function rebuild_panel_all(frame, pending, player_index)
    local panel_all = frame.content_flow.main_content_flow.left_panel.left_vertical_flow
        .left_scroll_pane.left_vertical_flow_content.dlc_frame_3.children[1].tasks_tab_content.tasks_panel_all
    if not panel_all then return end

    panel_all.clear()

    if not pending.tasks or #pending.tasks == 0 then
        panel_all.add{type="label", caption="Нет активных задач", style="label"}
        return
    end

    local grid_states = pending.grid_states
    local active_tasks = {}
    for _, task in ipairs(pending.tasks) do
        if not task.task_id then goto continue_task end
        local row, col = task.grid_row, task.grid_col
        if row and col and grid_states[row] and grid_states[row][col] then
            table.insert(active_tasks, task)
        end
        ::continue_task::
    end

    table.sort(active_tasks, function(a, b) return a.display_order < b.display_order end)

    if #active_tasks == 0 then
        panel_all.add{type="label", caption="Нет активных задач", style="label"}
        return
    end

    for _, task in ipairs(active_tasks) do
        task_block.create_task_block(panel_all, task, player_index, {show_move_buttons = true})
    end
end

-- Функция перестроения панели «Группы»
local function rebuild_panel_groups(frame, pending, player_index)
    local panel_groups = frame.content_flow.main_content_flow.left_panel.left_vertical_flow
        .left_scroll_pane.left_vertical_flow_content.dlc_frame_3.children[1].tasks_tab_content.tasks_panel_groups
    if not panel_groups then return end

    panel_groups.clear()

    local add_group_btn = panel_groups.add{
        type = "button",
        name = "add_group_button",
        caption = "+ Добавить группу",
        style = "button"
    }
    add_group_btn.style.width = 384
    add_group_btn.style.height = 36
    add_group_btn.style.horizontally_stretchable = false
    add_group_btn.style.horizontal_align = "left"
    add_group_btn.style.left_padding = 8
    add_group_btn.tags = { player_index = player_index }

    if pending.groups and #pending.groups > 0 then
        for _, group_data in ipairs(pending.groups) do
            group_block.create_group_block(panel_groups, group_data, player_index, pending)
        end
    else
        panel_groups.add{type="label", caption="Нет созданных групп", style="label"}
    end
end

-- Внутренняя функция для создания фрейма (общая для создания и редактирования)
local function create_frame_internal(player, player_index, pending, is_edit, frame_name, title_text, button_text)
    if player.gui.screen[frame_name] then
        player.gui.screen[frame_name].destroy()
        if global.pending_areas[player_index] then
            global.pending_areas[player_index] = nil
        end
        if global.player_main_frames[player_index] then
            global.player_main_frames[player_index] = nil
        end
        if global.player_name_labels[player_index] then
            global.player_name_labels[player_index] = nil
        end
        if player.opened and not player.opened.valid then
            player.opened = nil
        end
    end

    local frame = player.gui.screen.add{
        type = "frame",
        name = frame_name,
        direction = "vertical",
        style = "frame"
    }
    player.opened = frame

    -- НЕ используем frame.caption, чтобы не было системного заголовка
    -- Заголовок будет создан вручную в title_flow
    frame.style.width = 1080
    frame.style.height = 668
    frame.style.top_padding = 4
    frame.style.bottom_padding = 8
    frame.style.left_padding = 8
    frame.style.right_padding = 8
    frame.location = {420, 158}

    -- Собственный заголовок с перетаскиванием и кнопкой закрытия
    local title_flow = frame.add{type = "flow", direction = "horizontal", name = "title_flow"}
    title_flow.style.height = 32
    title_flow.style.bottom_padding = 4
    title_flow.style.horizontal_spacing = 8
    title_flow.style.vertical_align = "center"

    local title_label = title_flow.add{
        type = "label",
        caption = title_text,
        style = "frame_title"
    }

    local drag_filler = title_flow.add{
        type = "empty-widget",
        name = "title_drag_filler",
        style = "draggable_space_header"
    }
    drag_filler.style.height = 24
    drag_filler.style.horizontally_stretchable = true
    drag_filler.style.left_margin = 4
    drag_filler.style.right_margin = 4
    drag_filler.drag_target = frame

    local close_btn = title_flow.add{
        type = "sprite-button",
        name = "close_area_editor",
        sprite = "utility/close",
        style = "frame_action_button"
    }
    close_btn.style.width = 24
    close_btn.style.height = 24
    close_btn.style.padding = 0
    close_btn.tooltip = "Закрыть"

    local content_flow = frame.add{
        type = "flow",
        direction = "vertical",
        name = "content_flow"
    }
    content_flow.style.height = 616
    content_flow.style.vertically_stretchable = true
    content_flow.style.vertical_spacing = 4

    local main_content_flow = content_flow.add{
        type = "flow",
        direction = "horizontal",
        name = "main_content_flow"
    }
    main_content_flow.style.height = 572
    main_content_flow.style.horizontally_stretchable = true
    main_content_flow.style.horizontal_spacing = 12

    -- ========== ЛЕВАЯ ПАНЕЛЬ ==========
    local left_panel = main_content_flow.add{
        type = "frame",
        name = "left_panel",
        style = "inside_shallow_frame"
    }
    left_panel.style.width = 420
    left_panel.style.height = 572
    left_panel.style.padding = 0
    left_panel.style.horizontally_stretchable = false
    left_panel.style.vertically_stretchable = true

    local left_vertical = left_panel.add{
        type = "flow",
        direction = "vertical",
        name = "left_vertical_flow"
    }
    left_vertical.style.width = 420
    left_vertical.style.horizontally_stretchable = false
    left_vertical.style.vertically_stretchable = true
    left_vertical.style.padding = 0
    left_vertical.style.vertical_spacing = 0

    -- Секция заголовка (имя области)
    local title_section = left_vertical.add{
        type = "frame",
        name = "left_title_section",
        style = "subheader_frame"
    }
    title_section.style.height = 36
    title_section.style.width = 420
    title_section.style.horizontally_stretchable = false
    title_section.style.vertically_stretchable = false
    title_section.style.padding = 0

    for _, child in pairs(title_section.children) do
        if child.valid then child.destroy() end
    end

    local main_flow = title_section.add{
        type = "flow",
        direction = "horizontal",
        name = "left_title_main_flow"
    }
    main_flow.style.width = 420
    main_flow.style.horizontally_stretchable = false
    main_flow.style.height = 28
    main_flow.style.vertical_align = "center"
    main_flow.style.horizontal_spacing = 4

    local label_edit = main_flow.add{
        type = "flow",
        name = "left_title_blueprint_label_edit"
    }
    label_edit.style.width = 232
    label_edit.style.height = 24
    label_edit.style.horizontally_stretchable = false
    label_edit.style.horizontal_spacing = 4

    local textfield = label_edit.add{
        type = "textfield",
        name = "area_name_textfield",
        style = "textbox",
        visible = false
    }
    textfield.style.width = 200
    textfield.style.height = 28
    textfield.style.top_margin = -2

    local label = label_edit.add{
        type = "label",
        name = "area_name_label",
        caption = "<Безымянная область>",
        style = "bold_label"
    }
    label.style.width = nil
    label.style.maximal_width = 200
    label.style.left_margin = 8
    label.style.horizontal_align = "left"
    label.style.font = "default-semibold"
    label.style.font_color = {0.94, 0.88, 0.78}

    local edit_button = label_edit.add{
        type = "button",
        name = "area_name_edit_button",
        caption = "✎",
        style = "button"
    }
    edit_button.style.width = 16
    edit_button.style.height = 16
    edit_button.style.padding = 0
    edit_button.style.top_margin = 5
    edit_button.style.font = "default"
    edit_button.style.font_color = {0.8, 0.8, 0.8}
    edit_button.style.hovered_font_color = {1, 1, 1}
    edit_button.tooltip = "Редактировать имя области"

    global.player_name_labels = global.player_name_labels or {}
    global.player_name_textfields = global.player_name_textfields or {}
    global.player_name_buttons = global.player_name_buttons or {}
    global.player_name_labels[player_index] = label
    global.player_name_textfields[player_index] = textfield
    global.player_name_buttons[player_index] = edit_button

    local spacer = main_flow.add{
        type = "empty-widget",
        name = "left_title_spacer"
    }
    spacer.style.horizontally_stretchable = true
    spacer.style.width = 0

    local btn1 = main_flow.add{
        type = "sprite-button",
        name = "left_title_button_1",
        sprite = "my-reassign",
        style = "tool_button_blue"
    }
    btn1.style.width = 28
    btn1.style.height = 28

    local btn5 = main_flow.add{
        type = "sprite-button",
        name = "left_title_button_5",
        sprite = "export-icon-24",
        style = "tool_button"
    }
    btn5.style.width = 28
    btn5.style.height = 28

    local btn6 = main_flow.add{
        type = "sprite-button",
        name = "left_title_button_6",
        sprite = "trash-icon-24",
        style = "tool_button_red"
    }
    btn6.style.width = 28
    btn6.style.height = 28

    -- Область прокрутки
    local scroll_pane = left_vertical.add{
        type = "scroll-pane",
        name = "left_scroll_pane",
        style = "naked_scroll_pane"
    }
    scroll_pane.style.width = 420
    scroll_pane.style.vertically_stretchable = true
    scroll_pane.style.horizontally_stretchable = false
    scroll_pane.style.padding = 0

    local vertical_flow = scroll_pane.add{
        type = "flow",
        direction = "vertical",
        name = "left_vertical_flow_content"
    }
    vertical_flow.style.width = 408
    vertical_flow.style.horizontally_stretchable = false
    vertical_flow.style.vertically_stretchable = true
    vertical_flow.style.padding = 4
    vertical_flow.style.vertical_spacing = 4

    -- Фрейм 1: Описание
    local frame1 = vertical_flow.add{
        type = "frame",
        name = "dlc_frame_1",
        style = "bordered_frame"
    }
    frame1.style.width = 400
    frame1.style.horizontally_stretchable = false
    frame1.style.vertically_stretchable = false
    frame1.style.top_padding = 4
    frame1.style.bottom_padding = 8
    frame1.style.left_padding = 8
    frame1.style.right_padding = 8

    local frame1_vertical = frame1.add{type = "flow", direction = "vertical"}
    frame1_vertical.style.width = 384
    frame1_vertical.style.horizontally_stretchable = false
    frame1_vertical.style.vertical_spacing = 4

    frame1_vertical.add{type = "label", caption = "Описание", style = "caption_label"}

    local desc_flow = frame1_vertical.add{type = "flow", direction = "horizontal"}
    desc_flow.style.width = 384
    desc_flow.style.horizontally_stretchable = false
    desc_flow.style.vertical_align = "bottom"
    desc_flow.style.horizontal_spacing = 0

    local desc_textbox = desc_flow.add{
        type = "text-box",
        name = "area_description_textbox",
        style = "edit_blueprint_description_textbox"
    }
    desc_textbox.style.width = 356
    desc_textbox.style.horizontally_stretchable = false
    desc_textbox.style.height = 120
    desc_textbox.style.minimal_height = 120
    desc_textbox.text = ""
    desc_textbox.word_wrap = true

    local icon_button = desc_flow.add{
        type = "sprite-button",
        name = "area_icon_select_button",
        style = "choose_chat_icon_in_textbox_button"
    }
    icon_button.style.width = 28
    icon_button.style.height = 28
    icon_button.style.left_margin = -28
    icon_button.style.bottom_margin = 0
    icon_button.tooltip = "Выбрать иконку"

    -- Фрейм 2: Компоненты
    local frame2 = vertical_flow.add{
        type = "frame",
        name = "dlc_frame_2",
        style = "bordered_frame"
    }
    frame2.style.width = 400
    frame2.style.horizontally_stretchable = false
    frame2.style.vertically_stretchable = false
    frame2.style.top_padding = 4
    frame2.style.bottom_padding = 8
    frame2.style.left_padding = 8
    frame2.style.right_padding = 8

    local frame2_vertical = frame2.add{type = "flow", direction = "vertical"}
    frame2_vertical.style.width = 384
    frame2_vertical.style.horizontally_stretchable = false
    frame2_vertical.style.vertical_spacing = 4

    frame2_vertical.add{type = "label", caption = "Компоненты", style = "caption_label"}

    local slots_panel = frame2_vertical.add{
        type = "frame",
        name = "components_slots_frame",
        style = "inside_deep_frame"
    }
    slots_panel.style.width = 360
    slots_panel.style.horizontally_stretchable = false
    slots_panel.style.vertically_stretchable = false
    slots_panel.style.padding = 0

    local components_table = slots_panel.add{
        type = "table",
        name = "components_table",
        column_count = 10
    }
    components_table.style.width = 360
    components_table.style.horizontally_stretchable = false
    components_table.style.horizontal_spacing = 0
    components_table.style.vertical_spacing = 0
    components_table.style.cell_padding = 0

    -- Фрейм 3: Задачи
    local frame3 = vertical_flow.add{
        type = "frame",
        name = "dlc_frame_3",
        style = "bordered_frame"
    }
    frame3.style.width = 400
    frame3.style.horizontally_stretchable = false
    frame3.style.vertically_stretchable = true
    frame3.style.top_padding = 4
    frame3.style.bottom_padding = 8
    frame3.style.left_padding = 8
    frame3.style.right_padding = 8

    local frame3_vertical = frame3.add{type = "flow", direction = "vertical"}
    frame3_vertical.style.width = 384
    frame3_vertical.style.horizontally_stretchable = false
    frame3_vertical.style.vertical_spacing = 4

    frame3_vertical.add{type = "label", caption = "Задачи", style = "caption_label"}

    -- Кнопки вкладок
    local tabs_flow = frame3_vertical.add{
        type = "flow",
        direction = "horizontal",
        name = "tasks_tabs_flow"
    }
    tabs_flow.style.width = 384
    tabs_flow.style.horizontally_stretchable = false
    tabs_flow.style.height = 28

    local btn_all = tabs_flow.add{
        type = "button",
        name = "tasks_tab_all",
        caption = "Все",
        style = "button",
        tags = { player_index = player_index }
    }
    btn_all.style.horizontally_stretchable = true
    btn_all.style.height = 28
    btn_all.style.font_color = {0.9, 0.9, 0.9}
    btn_all.toggled = true

    local btn_groups = tabs_flow.add{
        type = "button",
        name = "tasks_tab_groups",
        caption = "Группы",
        style = "button",
        tags = { player_index = player_index }
    }
    btn_groups.style.horizontally_stretchable = true
    btn_groups.style.height = 28
    btn_groups.style.font_color = {0.7, 0.7, 0.7}
    btn_groups.toggled = false

    local btn_filters = tabs_flow.add{
        type = "button",
        name = "tasks_tab_filters",
        caption = "Фильтры",
        style = "button",
        tags = { player_index = player_index }
    }
    btn_filters.style.horizontally_stretchable = true
    btn_filters.style.height = 28
    btn_filters.style.font_color = {0.7, 0.7, 0.7}
    btn_filters.toggled = false

    -- Контейнер содержимого вкладок
    local tab_content = frame3_vertical.add{
        type = "flow",
        direction = "vertical",
        name = "tasks_tab_content"
    }
    tab_content.style.width = 384
    tab_content.style.horizontally_stretchable = false
    tab_content.style.vertically_stretchable = true

    -- Панель «Все»
    local panel_all = tab_content.add{
        type = "flow",
        direction = "vertical",
        name = "tasks_panel_all"
    }
    panel_all.style.width = 384
    panel_all.style.horizontally_stretchable = false
    panel_all.style.vertically_stretchable = true
    panel_all.style.vertical_spacing = 4
    panel_all.visible = true

    -- Панель «Группы»
    local panel_groups = tab_content.add{
        type = "flow",
        direction = "vertical",
        name = "tasks_panel_groups"
    }
    panel_groups.style.width = 384
    panel_groups.style.horizontally_stretchable = false
    panel_groups.style.vertically_stretchable = true
    panel_groups.visible = false

    -- Панель «Фильтры»
    local panel_filters = tab_content.add{
        type = "flow",
        direction = "vertical",
        name = "tasks_panel_filters"
    }
    panel_filters.style.width = 384
    panel_filters.style.horizontally_stretchable = false
    panel_filters.style.vertically_stretchable = true
    panel_filters.visible = false

    -- Фрейм 4 (заглушка)
    local frame4 = vertical_flow.add{
        type = "frame",
        name = "dlc_frame_4",
        style = "bordered_frame"
    }
    frame4.style.width = 400
    frame4.style.horizontally_stretchable = false
    frame4.style.vertically_stretchable = false
    frame4.style.top_padding = 4
    frame4.style.bottom_padding = 8
    frame4.style.left_padding = 8
    frame4.style.right_padding = 8
    local temp4 = frame4.add{type="label", caption="Параметры зоны 4", style="caption_label"}
    temp4.style.height = 28
    frame4.add{type="label", caption="Здесь будут прочие настройки"}

    local filler = vertical_flow.add{
        type = "empty-widget",
        style = "draggable_space"
    }
    filler.style.vertically_stretchable = true
    filler.style.height = 0

    -- ========== ПРАВАЯ ПАНЕЛЬ (сетка тайлов) ==========
    local right_panel = main_content_flow.add{
        type = "frame",
        name = "right_panel",
        style = "inside_shallow_frame"
    }
    right_panel.style.width = 612
    right_panel.style.height = 572
    right_panel.style.padding = 0

    local right_vertical = right_panel.add{
        type = "flow",
        direction = "vertical",
        name = "right_vertical_flow"
    }
    right_vertical.style.vertically_stretchable = true
    right_vertical.style.horizontally_stretchable = true
    right_vertical.style.padding = 0
    right_vertical.style.vertical_spacing = 0

    local subheader_frame = right_vertical.add{
        type = "frame",
        name = "right_subheader",
        style = "subheader_frame"
    }
    subheader_frame.style.height = 36
    subheader_frame.style.horizontally_stretchable = true
    subheader_frame.style.vertical_align = "center"
    subheader_frame.style.top_padding = 3
    subheader_frame.style.bottom_padding = 1
    subheader_frame.style.left_padding = 4
    subheader_frame.style.right_padding = 4

    local subheader_flow = subheader_frame.add{
        type = "flow",
        direction = "horizontal",
        name = "right_subheader_flow"
    }
    subheader_flow.style.vertical_align = "center"
    subheader_flow.style.horizontally_stretchable = true
    subheader_flow.style.horizontal_spacing = 8

    subheader_flow.add{
        type = "label",
        caption = "Выбор тайлов",
        style = "subheader_caption_label"
    }
    subheader_flow.add{
        type = "label",
        caption = "Кликните на тайл, чтобы включить/выключить",
        style = "subheader_right_aligned_label"
    }

    local panel_width = 612
    local panel_height = 572
    local header_height = 36
    local right_scroll_pane_height = panel_height - header_height

    local right_scroll_pane = right_vertical.add{
        type = "scroll-pane",
        name = "tile_grid_scroll"
    }
    right_scroll_pane.style.height = right_scroll_pane_height
    right_scroll_pane.style.width = panel_width
    right_scroll_pane.style.vertically_stretchable = false
    right_scroll_pane.style.horizontally_stretchable = false

    local width = pending.width
    local height = pending.height
    local grid_states = pending.grid_states

    local grid_container = right_scroll_pane.add{
        type = "table",
        name = "tile_grid_container",
        column_count = width
    }
    grid_container.style.horizontal_spacing = 0
    grid_container.style.vertical_spacing = 0
    grid_container.style.cell_padding = 0

    local CELL_SIZE = 32
    grid_container.style.width = width * CELL_SIZE
    grid_container.style.height = height * CELL_SIZE

    global.tile_states = global.tile_states or {}
    if not global.tile_states[player_index] then
        global.tile_states[player_index] = {}
    end
    local states = global.tile_states[player_index]

    for row = 1, height do
        if not states[row] then states[row] = {} end
        for col = 1, width do
            if states[row][col] == nil then
                states[row][col] = grid_states[row][col]
            end
            local state = states[row][col]
            local sprite_name = get_cell_sprite(row, col, pending, state)

            local button = grid_container.add{
                type = "sprite-button",
                name = string.format("cell_%d_%d", col, row),
                sprite = sprite_name,
                style = "dlc_cell"
            }
            button.style.width = CELL_SIZE
            button.style.height = CELL_SIZE
            button.tags = {
                player_index = player_index,
                row = row,
                col = col
            }
        end
    end

    -- Нижняя панель
    local bottom_flow = content_flow.add{
        type = "flow",
        direction = "horizontal",
        name = "bottom_flow",
        style = "dialog_buttons_horizontal_flow"
    }
    bottom_flow.style.height = 40
    bottom_flow.style.horizontally_stretchable = true

    local bottom_filler = bottom_flow.add{
        type = "empty-widget",
        name = "bottom_filler",
        style = "draggable_space"
    }
    bottom_filler.style.horizontally_stretchable = true
    bottom_filler.style.vertically_stretchable = true
    bottom_filler.style.height = 32
    bottom_filler.drag_target = frame

    local right_button_flow = bottom_flow.add{
        type = "flow",
        direction = "horizontal",
        name = "bottom_right_flow"
    }
    right_button_flow.style.horizontal_align = "right"

    local confirm_button = right_button_flow.add{
        type = "button",
        name = "area_create_confirm",
        caption = button_text,
        style = "confirm_button"
    }
    confirm_button.style.height = 32

    refresh_components_frame_only(frame, player_index)

    -- Построить панели при открытии
    rebuild_panel_all(frame, pending, player_index)
    filter_panel.build_filter_panel(panel_filters, pending, player_index)
    rebuild_panel_groups(frame, pending, player_index)

    global.player_main_frames[player_index] = frame
    return frame, label
end

-- Публичная функция для создания новой области
function area_editor.create_new_area_frame(player, player_index, pending)
    return create_frame_internal(player, player_index, pending, false,
        "area_editor_frame",
        "Настройка новой области",
        "Создать область")
end

-- Публичная функция для редактирования существующей области
function area_editor.create_edit_area_frame(player, player_index, pending)
    return create_frame_internal(player, player_index, pending, true,
        "area_editor_edit_frame",
        "Редактирование области",
        "Сохранить область")
end

function area_editor.refresh_tasks_frame(player_index)
    local frame = global.player_main_frames[player_index]
    if frame and frame.valid then
        refresh_components_frame_only(frame, player_index)
        local pending = global.pending_areas[player_index]
        if pending then
            local panel_all = frame.content_flow.main_content_flow.left_panel.left_vertical_flow
                .left_scroll_pane.left_vertical_flow_content.dlc_frame_3.children[1].tasks_tab_content.tasks_panel_all
            if panel_all and panel_all.visible then
                rebuild_panel_all(frame, pending, player_index)
            end

            local panel_filters = frame.content_flow.main_content_flow.left_panel.left_vertical_flow
                .left_scroll_pane.left_vertical_flow_content.dlc_frame_3.children[1].tasks_tab_content.tasks_panel_filters
            if panel_filters and panel_filters.visible then
                filter_panel.build_filter_panel(panel_filters, pending, player_index)
            end

            local panel_groups = frame.content_flow.main_content_flow.left_panel.left_vertical_flow
                .left_scroll_pane.left_vertical_flow_content.dlc_frame_3.children[1].tasks_tab_content.tasks_panel_groups
            if panel_groups and panel_groups.visible then
                rebuild_panel_groups(frame, pending, player_index)
            end
        end
        local player = game.players[player_index]
        if player then
            player.print("Список задач обновлён.")
        end
    end
end

function area_editor.create_name_dialog(player, current_name)
    return nil
end

function area_editor.update_preview(player_index)
end

-- ЯВНЫЙ ВОЗВРАТ ВСЕХ ПУБЛИЧНЫХ ФУНКЦИЙ
return {
    create_new_area_frame = area_editor.create_new_area_frame,
    create_edit_area_frame = area_editor.create_edit_area_frame,
    refresh_tasks_frame = area_editor.refresh_tasks_frame,
    create_name_dialog = area_editor.create_name_dialog,
    update_preview = area_editor.update_preview
}