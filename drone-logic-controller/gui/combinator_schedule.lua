-- gui/combinator_schedule.lua
local combinator_schedule = {}

-- === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ДЛЯ РАБОТЫ С ГРУППАМИ И ОБЛАСТЯМИ ===
local function set_group_children_state(unit_number, group_id, state)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end
    for _, area in ipairs(data.areas[group_id] or {}) do
        area.enabled = state
        if area.construction_data then area.construction_data.enabled = state end
        if area.logistic_data then area.logistic_data.enabled = state end
        for _, task in ipairs(area.construction_data and area.construction_data.tasks or {}) do
            task.enabled = state
        end
        for _, link in ipairs(area.construction_data and area.construction_data.links or {}) do
            link.enabled = state
        end
        for _, task in ipairs(area.logistic_data and area.logistic_data.tasks or {}) do
            task.enabled = state
        end
        for _, link in ipairs(area.logistic_data and area.logistic_data.links or {}) do
            link.enabled = state
        end
    end
end

local function create_area_with_group_state(unit_number, group_id, new_area)
    local data = global.combinator_areas[unit_number]
    if not data then return end
    local group = nil
    for _, g in ipairs(data.groups) do
        if g.id == group_id then group = g; break end
    end
    if group and group.enabled == false then
        new_area.enabled = false
        if new_area.construction_data then new_area.construction_data.enabled = false end
        if new_area.logistic_data then new_area.logistic_data.enabled = false end
    end
end

local function create_item_with_parent_state(unit_number, group_id, area_id, section_kind, item)
    local data = global.combinator_areas[unit_number]
    if not data then return end
    local group = nil
    for _, g in ipairs(data.groups) do
        if g.id == group_id then group = g; break end
    end
    local area = nil
    for _, a in ipairs(data.areas[group_id] or {}) do
        if a.id == area_id then area = a; break end
    end
    if (group and group.enabled == false) or (area and area.enabled == false) then
        item.enabled = false
    end
    local section = (section_kind == "construction") and area.construction_data or area.logistic_data
    if section and section.enabled == false then
        item.enabled = false
    end
end

-- === GUI ЭЛЕМЕНТЫ ===
local function create_drone_slot(parent, unit_number, group_id, drone_type, value)
    local btn = parent.add({
        type = "sprite-button",
        name = string.format("combinator_group_%s_slot_%d_%d", drone_type, unit_number, group_id),
        sprite = (drone_type == "logistic") and "entity/logistic-robot" or "entity/construction-robot",
        style = "slot_button",
        caption = tostring(value or 0),
    })
    btn.style.width = 24
    btn.style.height = 24
    btn.style.font = "default-small-bold"
    btn.style.font_color = {1,1,1}
    btn.style.horizontal_align = "right"
    btn.style.vertical_align = "bottom"
    btn.tags = { unit_number = unit_number, group_id = group_id, drone_type = drone_type, value = value or 0 }
    return btn
end

local function create_standard_button(parent, name, caption, sprite, style, tags)
    local btn
    if sprite then
        btn = parent.add({
            type = "sprite-button",
            name = name,
            sprite = sprite,
            style = style or "tool_button",
            tags = tags
        })
    else
        btn = parent.add({
            type = "button",
            name = name,
            caption = caption,
            style = style or "tool_button",
            tags = tags
        })
    end
    btn.style.width = 24
    btn.style.height = 24
    return btn
end

local function add_placeholder(parent)
    local ph = parent.add({ type = "empty-widget" })
    ph.style.width = 24
    ph.style.height = 24
    return ph
end

local function create_group_frame(parent, unit_number, group)
    local gid = group.id
    local group_frame = parent.add({ type = "frame", style = "shallow_frame" })
    group_frame.style.width = 392
    group_frame.style.height = 36
    group_frame.style.padding = {2,2,2,2}
    group_frame.style.margin = {0,0,2,0}
    local row = group_frame.add({ type = "flow", direction = "horizontal" })
    row.style.vertical_align = "center"
    row.style.horizontal_spacing = 1
    row.style.horizontally_stretchable = true

    local left_flow = row.add({ type = "flow", direction = "horizontal" })
    left_flow.style.horizontal_spacing = 1
    left_flow.style.vertically_stretchable = true

    create_drone_slot(left_flow, unit_number, gid, "logistic", group.logistic or 0)
    create_drone_slot(left_flow, unit_number, gid, "construction", group.construction or 0)

    local name_label = left_flow.add({
        type = "label",
        name = string.format("combinator_group_name_label_%d_%d", unit_number, gid),
        caption = group.name or "Новая группа",
        style = "bold_label"
    })
    name_label.style.height = 24
    name_label.style.maximal_width = 120
    name_label.style.font = "default-semibold"
    name_label.style.vertical_align = "center"
    name_label.visible = true

    local name_field = left_flow.add({
        type = "textfield",
        name = string.format("combinator_group_name_field_%d_%d", unit_number, gid),
        text = group.name or "Новая группа",
        style = "textbox",
        visible = false
    })
    name_field.style.width = 120
    name_field.style.height = 24
    name_field.tags = { unit_number = unit_number, group_id = gid }

    local spacer = row.add({ type = "empty-widget", style = "draggable_space" })
    spacer.style.horizontally_stretchable = true

    local right_flow = row.add({ type = "flow", direction = "horizontal" })
    right_flow.style.horizontal_spacing = 1
    right_flow.style.vertical_align = "center"

    create_standard_button(right_flow,
        string.format("combinator_group_edit_name_%d_%d", unit_number, gid),
        nil, "utility/rename_icon", "tool_button",
        { unit_number = unit_number, group_id = gid })

    create_standard_button(right_flow,
        string.format("combinator_group_move_up_%d_%d", unit_number, gid),
        "▲", nil, "tool_button",
        { unit_number = unit_number, group_id = gid })

    create_standard_button(right_flow,
        string.format("combinator_group_move_down_%d_%d", unit_number, gid),
        "▼", nil, "tool_button",
        { unit_number = unit_number, group_id = gid })

    local enabled = (group.enabled ~= false)
    create_standard_button(right_flow,
        string.format("combinator_group_toggle_%d_%d", unit_number, gid),
        nil, enabled and "utility/play" or "utility/stop", "tool_button",
        { unit_number = unit_number, group_id = gid })

    create_standard_button(right_flow,
        string.format("combinator_group_delete_%d_%d", unit_number, gid),
        nil, "utility/trash", "tool_button_red",
        { unit_number = unit_number, group_id = gid })

    return group_frame
end

local function create_area_frame(parent, unit_number, group_id, area)
    local area_id = area.id
    local area_frame = parent.add({ type = "frame", style = "shallow_frame" })
    area_frame.style.width = 350
    area_frame.style.height = 36
    area_frame.style.padding = {2,2,2,2}
    area_frame.style.margin = {0,0,2,0}
    local row = area_frame.add({ type = "flow", direction = "horizontal" })
    row.style.vertical_align = "center"
    row.style.horizontal_spacing = 1
    row.style.horizontally_stretchable = true

    local left_flow = row.add({ type = "flow", direction = "horizontal" })
    left_flow.style.horizontal_spacing = 1
    left_flow.style.vertically_stretchable = true

    -- Отображаем имя глобальной области, если есть ссылка
    local display_name = area.name
    if area.global_area_id and global.areas[area.global_area_id] then
        display_name = global.areas[area.global_area_id].name
    end
    local name_label = left_flow.add({
        type = "label",
        caption = display_name or "Новая область",
        style = "label"
    })
    name_label.style.height = 24
    name_label.style.maximal_width = 220

    local spacer = row.add({ type = "empty-widget", style = "draggable_space" })
    spacer.style.horizontally_stretchable = true

    local right_flow = row.add({ type = "flow", direction = "horizontal" })
    right_flow.style.horizontal_spacing = 1
    right_flow.style.vertical_align = "center"

    add_placeholder(right_flow)

    create_standard_button(right_flow,
        string.format("combinator_area_move_up_%d_%d_%d", unit_number, group_id, area_id),
        "▲", nil, "tool_button",
        { unit_number = unit_number, group_id = group_id, area_id = area_id })

    create_standard_button(right_flow,
        string.format("combinator_area_move_down_%d_%d_%d", unit_number, group_id, area_id),
        "▼", nil, "tool_button",
        { unit_number = unit_number, group_id = group_id, area_id = area_id })

    local area_enabled = (area.enabled ~= false)
    create_standard_button(right_flow,
        string.format("combinator_area_stop_%d_%d_%d", unit_number, group_id, area_id),
        nil, area_enabled and "utility/play" or "utility/stop", "tool_button",
        { unit_number = unit_number, group_id = group_id, area_id = area_id })

    create_standard_button(right_flow,
        string.format("combinator_area_delete_%d_%d_%d", unit_number, group_id, area_id),
        nil, "utility/trash", "tool_button_red",
        { unit_number = unit_number, group_id = group_id, area_id = area_id })

    return area_frame
end

local function create_section_drone_slot(parent, unit_number, group_id, area_id, kind, used, total)
    local btn = parent.add({
        type = "sprite-button",
        name = string.format("area_drone_slot_%d_%d_%d_%s", unit_number, group_id, area_id, kind),
        sprite = (kind == "construction") and "entity/construction-robot" or "entity/logistic-robot",
        style = "slot_button",
        caption = string.format("%d/%d", used, total),
        tags = { unit_number = unit_number, group_id = group_id, area_id = area_id, kind = kind }
    })
    btn.style.width = 40
    btn.style.height = 24
    btn.style.font = "default-small-bold"
    btn.style.font_color = {1,1,1}
    btn.style.horizontal_align = "center"
    btn.style.vertical_align = "center"
    return btn
end

local function create_item_block(parent, unit_number, group_id, area_id, section_kind, item_kind, items)
    local block_flow = parent.add({ type = "flow", direction = "vertical" })
    block_flow.style.width = 280
    block_flow.style.horizontal_align = "right"
    block_flow.style.margin = {0,0,4,0}

    local container = block_flow.add({ type = "flow", direction = "vertical" })
    container.style.width = 280

    for _, item in ipairs(items) do
        local item_frame = container.add({ type = "frame", style = "shallow_frame" })
        item_frame.style.width = 280
        item_frame.style.height = 36
        item_frame.style.padding = {2,2,2,2}
        item_frame.style.margin = {0,0,2,0}
        local row = item_frame.add({ type = "flow", direction = "horizontal" })
        row.style.vertical_align = "center"
        row.style.horizontal_spacing = 1
        row.style.horizontally_stretchable = true

        local left_flow = row.add({ type = "flow", direction = "horizontal" })
        left_flow.style.horizontal_spacing = 1
        left_flow.style.vertically_stretchable = true

        local drone_slot = left_flow.add({
            type = "sprite-button",
            name = string.format("%s_item_drone_slot_%d_%d_%d_%s_%d", item_kind, unit_number, group_id, area_id, section_kind, item.id),
            sprite = (section_kind == "construction") and "entity/construction-robot" or "entity/logistic-robot",
            style = "slot_button",
            caption = tostring(item.drone_count or 0),
            tags = { unit_number = unit_number, group_id = group_id, area_id = area_id, section_kind = section_kind, item_kind = item_kind, item_id = item.id }
        })
        drone_slot.style.width = 24
        drone_slot.style.height = 24
        drone_slot.style.font = "default-small-bold"
        drone_slot.style.font_color = {1,1,1}
        drone_slot.style.horizontal_align = "right"
        drone_slot.style.vertical_align = "bottom"

        local chest_slot = left_flow.add({
            type = "sprite-button",
            name = string.format("%s_item_chest_slot_%d_%d_%d_%s_%d", item_kind, unit_number, group_id, area_id, section_kind, item.id),
            sprite = "entity/storage-chest",
            style = "slot_button",
            tags = { unit_number = unit_number, group_id = group_id, area_id = area_id, section_kind = section_kind, item_kind = item_kind, item_id = item.id }
        })
        chest_slot.style.width = 24
        chest_slot.style.height = 24

        local name_label = left_flow.add({
            type = "label",
            name = string.format("%s_item_name_label_%d_%d_%d_%s_%d", item_kind, unit_number, group_id, area_id, section_kind, item.id),
            caption = item.name or ((item_kind == "task") and "Новая задача" or "Новая связь"),
            style = "label",
            visible = true
        })
        name_label.style.height = 24
        name_label.style.maximal_width = 140

        local name_field = left_flow.add({
            type = "textfield",
            name = string.format("%s_item_name_field_%d_%d_%d_%s_%d", item_kind, unit_number, group_id, area_id, section_kind, item.id),
            text = item.name or "",
            style = "textbox",
            visible = false
        })
        name_field.style.width = 140
        name_field.style.height = 24
        name_field.tags = { unit_number = unit_number, group_id = group_id, area_id = area_id, section_kind = section_kind, item_kind = item_kind, item_id = item.id }

        local spacer = row.add({ type = "empty-widget", style = "draggable_space" })
        spacer.style.horizontally_stretchable = true

        local right_flow = row.add({ type = "flow", direction = "horizontal" })
        right_flow.style.horizontal_spacing = 1
        right_flow.style.vertical_align = "center"

        create_standard_button(right_flow,
            string.format("%s_item_edit_name_%d_%d_%d_%s_%d", item_kind, unit_number, group_id, area_id, section_kind, item.id),
            nil, "utility/rename_icon", "tool_button",
            { unit_number = unit_number, group_id = group_id, area_id = area_id, section_kind = section_kind, item_kind = item_kind, item_id = item.id })

        create_standard_button(right_flow,
            string.format("%s_item_move_up_%d_%d_%d_%s_%d", item_kind, unit_number, group_id, area_id, section_kind, item.id),
            "▲", nil, "tool_button",
            { unit_number = unit_number, group_id = group_id, area_id = area_id, section_kind = section_kind, item_kind = item_kind, item_id = item.id })

        create_standard_button(right_flow,
            string.format("%s_item_move_down_%d_%d_%d_%s_%d", item_kind, unit_number, group_id, area_id, section_kind, item.id),
            "▼", nil, "tool_button",
            { unit_number = unit_number, group_id = group_id, area_id = area_id, section_kind = section_kind, item_kind = item_kind, item_id = item.id })

        local enabled = (item.enabled ~= false)
        create_standard_button(right_flow,
            string.format("%s_item_toggle_%d_%d_%d_%s_%d", item_kind, unit_number, group_id, area_id, section_kind, item.id),
            nil, enabled and "utility/play" or "utility/stop", "tool_button",
            { unit_number = unit_number, group_id = group_id, area_id = area_id, section_kind = section_kind, item_kind = item_kind, item_id = item.id })

        create_standard_button(right_flow,
            string.format("%s_item_delete_%d_%d_%d_%s_%d", item_kind, unit_number, group_id, area_id, section_kind, item.id),
            nil, "utility/trash", "tool_button_red",
            { unit_number = unit_number, group_id = group_id, area_id = area_id, section_kind = section_kind, item_kind = item_kind, item_id = item.id })
    end

    local add_btn = block_flow.add({
        type = "button",
        name = string.format("add_%s_%s_%d_%d_%d", section_kind, item_kind, unit_number, group_id, area_id),
        caption = (item_kind == "task") and "+ Добавить задачу" or "+ Добавить связь",
        style = "button"
    })
    add_btn.style.width = 280
    add_btn.style.height = 36
    add_btn.style.horizontal_align = "left"
    add_btn.style.left_padding = 8
    add_btn.tags = { unit_number = unit_number, group_id = group_id, area_id = area_id, section_kind = section_kind, item_kind = item_kind }

    return block_flow
end

local function create_main_task_section(parent, unit_number, group_id, area_id, kind, data, sibling_kind)
    if data.auto_distribute_tasks == nil then
        data.auto_distribute_tasks = true
    end

    local section_flow = parent.add({ type = "flow", direction = "vertical" })
    section_flow.style.width = 300
    section_flow.style.horizontally_stretchable = false
    section_flow.style.vertical_spacing = 2
    section_flow.style.margin = {0,0,4,0}
    section_flow.style.horizontal_align = "right"

    local header_frame = section_flow.add({ type = "frame", style = "shallow_frame" })
    header_frame.style.width = 300
    header_frame.style.height = 36
    header_frame.style.padding = {2,2,2,2}
    local row = header_frame.add({ type = "flow", direction = "horizontal" })
    row.style.vertical_align = "center"
    row.style.horizontal_spacing = 1
    row.style.horizontally_stretchable = true

    local left_flow = row.add({ type = "flow", direction = "horizontal" })
    left_flow.style.horizontal_spacing = 1
    left_flow.style.vertically_stretchable = true

    local used = 0
    for _, task in ipairs(data.tasks or {}) do
        used = used + (task.drone_count or 0)
    end
    for _, link in ipairs(data.links or {}) do
        used = used + (link.drone_count or 0)
    end
    local total = data.drone_count or 0

    create_section_drone_slot(left_flow, unit_number, group_id, area_id, kind, used, total)

    local name_label = left_flow.add({
        type = "label",
        caption = (kind == "construction") and "Строительные задачи" or "Логистические задачи",
        style = "bold_label"
    })
    name_label.style.height = 24
    name_label.style.maximal_width = 260

    local spacer = row.add({ type = "empty-widget", style = "draggable_space" })
    spacer.style.horizontally_stretchable = true

    local right_flow = row.add({ type = "flow", direction = "horizontal" })
    right_flow.style.horizontal_spacing = 1
    right_flow.style.vertical_align = "center"

    add_placeholder(right_flow)

    create_standard_button(right_flow,
        string.format("move_%s_section_up_%d_%d_%d", kind, unit_number, group_id, area_id),
        "▲", nil, "tool_button",
        { unit_number = unit_number, group_id = group_id, area_id = area_id, section_kind = kind, target_kind = sibling_kind })

    create_standard_button(right_flow,
        string.format("move_%s_section_down_%d_%d_%d", kind, unit_number, group_id, area_id),
        "▼", nil, "tool_button",
        { unit_number = unit_number, group_id = group_id, area_id = area_id, section_kind = kind, target_kind = sibling_kind })

    local enabled = (data.enabled ~= false)
    create_standard_button(right_flow,
        string.format("toggle_%s_section_%d_%d_%d", kind, unit_number, group_id, area_id),
        nil, enabled and "utility/play" or "utility/stop", "tool_button",
        { unit_number = unit_number, group_id = group_id, area_id = area_id, section_kind = kind })

    add_placeholder(right_flow)

    local items_flow = section_flow.add({ type = "flow", direction = "vertical" })
    items_flow.style.width = 280
    items_flow.style.horizontal_align = "right"

    if data.tasks then
        create_item_block(items_flow, unit_number, group_id, area_id, kind, "task", data.tasks)
    end
    if data.links then
        create_item_block(items_flow, unit_number, group_id, area_id, kind, "link", data.links)
    end

    return section_flow
end

-- === ЛОГИКА СИНХРОНИЗАЦИИ ДРОНОВ ГРУППЫ ===
local function has_manual_drone_count(area, kind)
    if kind == "logistic" then
        return area.manual_logistic == true
    else
        return area.manual_construction == true
    end
end

local function get_manual_drone_count(area, kind)
    if kind == "logistic" and area.manual_logistic then
        return area.manual_logistic_value
    elseif kind == "construction" and area.manual_construction then
        return area.manual_construction_value
    end
    return nil
end

function combinator_schedule.set_area_drone_count(unit_number, group_id, area_id, kind, value)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end
    for _, area in ipairs(data.areas[group_id]) do
        if area.id == area_id then
            if kind == "logistic" then
                area.manual_logistic = true
                area.manual_logistic_value = value
                area.logistic_data.drone_count = value
                if area.logistic_data.auto_distribute_tasks then
                    combinator_schedule.sync_tasks_for_section(unit_number, group_id, area_id, "logistic")
                end
            else
                area.manual_construction = true
                area.manual_construction_value = value
                area.construction_data.drone_count = value
                if area.construction_data.auto_distribute_tasks then
                    combinator_schedule.sync_tasks_for_section(unit_number, group_id, area_id, "construction")
                end
            end
            break
        end
    end
    combinator_schedule.sync_drone_counts_for_group(unit_number, group_id)
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.reset_area_drone_count(unit_number, group_id, area_id, kind)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end
    for _, area in ipairs(data.areas[group_id]) do
        if area.id == area_id then
            if kind == "logistic" then
                area.manual_logistic = nil
                area.manual_logistic_value = nil
            else
                area.manual_construction = nil
                area.manual_construction_value = nil
            end
            break
        end
    end
    combinator_schedule.sync_drone_counts_for_group(unit_number, group_id)
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.sync_drone_counts_for_group(unit_number, group_id)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end

    local group = nil
    for _, g in ipairs(data.groups) do
        if g.id == group_id then group = g; break end
    end
    if not group then return end

    local areas = data.areas[group_id] or {}
    local total_logistic = group.logistic or 0
    local total_construction = group.construction or 0

    local manual_logistic_sum = 0
    local manual_construction_sum = 0
    local auto_areas_logistic = {}
    local auto_areas_construction = {}

    for _, area in ipairs(areas) do
        if has_manual_drone_count(area, "logistic") then
            manual_logistic_sum = manual_logistic_sum + (get_manual_drone_count(area, "logistic") or 0)
        else
            table.insert(auto_areas_logistic, area)
        end
        if has_manual_drone_count(area, "construction") then
            manual_construction_sum = manual_construction_sum + (get_manual_drone_count(area, "construction") or 0)
        else
            table.insert(auto_areas_construction, area)
        end
    end

    local remaining_logistic = total_logistic - manual_logistic_sum
    local remaining_construction = total_construction - manual_construction_sum
    if remaining_logistic < 0 then remaining_logistic = 0 end
    if remaining_construction < 0 then remaining_construction = 0 end

    local num_auto_logistic = #auto_areas_logistic
    local num_auto_construction = #auto_areas_construction

    if num_auto_logistic > 0 then
        local base = math.floor(remaining_logistic / num_auto_logistic)
        local remainder = remaining_logistic % num_auto_logistic
        for i, area in ipairs(auto_areas_logistic) do
            local count = base
            if i <= remainder then count = count + 1 end
            area.logistic_data.drone_count = count
            if area.logistic_data.auto_distribute_tasks then
                combinator_schedule.sync_tasks_for_section(unit_number, group_id, area.id, "logistic")
            end
        end
    end

    if num_auto_construction > 0 then
        local base = math.floor(remaining_construction / num_auto_construction)
        local remainder = remaining_construction % num_auto_construction
        for i, area in ipairs(auto_areas_construction) do
            local count = base
            if i <= remainder then count = count + 1 end
            area.construction_data.drone_count = count
            if area.construction_data.auto_distribute_tasks then
                combinator_schedule.sync_tasks_for_section(unit_number, group_id, area.id, "construction")
            end
        end
    end
end

-- === ФУНКЦИИ ДЛЯ АВТОРАСПРЕДЕЛЕНИЯ ПО ЗАДАЧАМ/СВЯЗЯМ ===
function combinator_schedule.set_section_auto_distribute(unit_number, group_id, area_id, kind, state)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end
    for _, area in ipairs(data.areas[group_id]) do
        if area.id == area_id then
            local section = (kind == "logistic") and area.logistic_data or area.construction_data
            if section then
                section.auto_distribute_tasks = state
                if not state then
                    for _, task in ipairs(section.tasks or {}) do
                        task.drone_count = 0
                    end
                    for _, link in ipairs(section.links or {}) do
                        link.drone_count = 0
                    end
                elseif state then
                    combinator_schedule.sync_tasks_for_section(unit_number, group_id, area_id, kind)
                end
            end
            break
        end
    end
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.sync_tasks_for_section(unit_number, group_id, area_id, kind)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end
    local area = nil
    for _, a in ipairs(data.areas[group_id]) do
        if a.id == area_id then area = a; break end
    end
    if not area then return end
    local section = (kind == "logistic") and area.logistic_data or area.construction_data
    if not section or not section.auto_distribute_tasks then return end

    local total = section.drone_count or 0
    local tasks = section.tasks or {}
    local links = section.links or {}
    local all_items = {}
    for _, t in ipairs(tasks) do table.insert(all_items, t) end
    for _, l in ipairs(links) do table.insert(all_items, l) end
    local count = #all_items
    if count == 0 then return end

    local base = math.floor(total / count)
    local remainder = total % count
    for i, item in ipairs(all_items) do
        local val = base
        if i <= remainder then val = val + 1 end
        item.drone_count = val
    end
end

function combinator_schedule.set_task_drone_count(unit_number, group_id, area_id, section_kind, item_kind, item_id, new_value)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end
    local area = nil
    for _, a in ipairs(data.areas[group_id]) do
        if a.id == area_id then area = a; break end
    end
    if not area then return end
    local section = (section_kind == "logistic") and area.logistic_data or area.construction_data
    if not section then return end
    if section.auto_distribute_tasks then
        return
    end
    local items = (item_kind == "task") and section.tasks or section.links
    local used_others = 0
    for _, it in ipairs(items) do
        if it.id ~= item_id then
            used_others = used_others + (it.drone_count or 0)
        end
    end
    local max_allowed = (section.drone_count or 0) - used_others
    if max_allowed < 0 then max_allowed = 0 end
    local final_value = math.min(new_value, max_allowed)
    for _, it in ipairs(items) do
        if it.id == item_id then
            it.drone_count = final_value
            break
        end
    end
    combinator_schedule.refresh(unit_number)
end

-- === ФУНКЦИИ ДЛЯ УПРАВЛЕНИЯ ОБЪЕКТАМИ СТРОИТЕЛЬНОЙ ЗАДАЧИ ===
function combinator_schedule.move_construction_object(unit_number, group_id, area_id, task_id, obj_index, direction)
    local data = global.combinator_areas[unit_number]
    if not data then return end
    local area = nil
    for _, a in ipairs(data.areas[group_id] or {}) do
        if a.id == area_id then area = a; break end
    end
    if not area then return end
    local task = nil
    for _, t in ipairs(area.construction_data.tasks or {}) do
        if t.id == task_id then task = t; break end
    end
    if not task or not task.construction_objects then return end
    local objects = task.construction_objects
    local new_index = obj_index + direction
    if new_index >= 1 and new_index <= #objects then
        objects[obj_index], objects[new_index] = objects[new_index], objects[obj_index]
    end
end

function combinator_schedule.set_construction_object_visibility(unit_number, group_id, area_id, task_id, obj_name, visible)
    local data = global.combinator_areas[unit_number]
    if not data then return end
    local area = nil
    for _, a in ipairs(data.areas[group_id] or {}) do
        if a.id == area_id then area = a; break end
    end
    if not area then return end
    local task = nil
    for _, t in ipairs(area.construction_data.tasks or {}) do
        if t.id == task_id then task = t; break end
    end
    if not task or not task.construction_objects then return end
    for _, obj in ipairs(task.construction_objects) do
        if obj.name == obj_name then
            obj.visible = visible
        end
    end
end

-- === НОВАЯ ФУНКЦИЯ: ДОБАВЛЕНИЕ УЖЕ СУЩЕСТВУЮЩЕЙ ГЛОБАЛЬНОЙ ОБЛАСТИ ===
function combinator_schedule.add_existing_area(unit_number, group_id, global_area_id)
    local data = global.combinator_areas[unit_number]
    if not data then return end
    local zone = global.areas[global_area_id]
    if not zone then return end

    -- Проверяем, не добавлена ли уже эта глобальная область в эту группу
    if data.areas[group_id] then
        for _, area in ipairs(data.areas[group_id]) do
            if area.global_area_id == global_area_id then
                return  -- уже есть
            end
        end
    end

    if not data.next_area_id then data.next_area_id = 1 end
    local new_id = data.next_area_id
    data.next_area_id = new_id + 1

    local new_area = {
        id = new_id,
        global_area_id = global_area_id,
        name = zone.name,
        enabled = true,
        construction_data = { enabled = true, drone_count = 0, tasks = {}, links = {}, auto_distribute_tasks = true },
        logistic_data = { enabled = true, drone_count = 0, tasks = {}, links = {}, auto_distribute_tasks = true }
    }

    if not data.areas[group_id] then data.areas[group_id] = {} end
    table.insert(data.areas[group_id], new_area)

    combinator_schedule.sync_drone_counts_for_group(unit_number, group_id)
    combinator_schedule.refresh(unit_number)
end

-- === ФУНКЦИИ УПРАВЛЕНИЯ ДАННЫМИ ===
function combinator_schedule.add_group(unit_number)
    local data = global.combinator_areas[unit_number]
    if not data then return end
    local new_id = data.next_group_id or 1
    data.next_group_id = new_id + 1
    table.insert(data.groups, {
        id = new_id,
        name = "Новая группа",
        logistic = 0,
        construction = 0,
        enabled = true,
    })
    if not data.areas then data.areas = {} end
    data.areas[new_id] = {}
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.delete_group(unit_number, group_id)
    local data = global.combinator_areas[unit_number]
    if not data or not data.groups then return end
    for i, g in ipairs(data.groups) do
        if g.id == group_id then
            table.remove(data.groups, i)
            break
        end
    end
    if data.areas then data.areas[group_id] = nil end
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.move_group_up(unit_number, group_id)
    local data = global.combinator_areas[unit_number]
    if not data or not data.groups then return end
    for i, g in ipairs(data.groups) do
        if g.id == group_id and i > 1 then
            data.groups[i], data.groups[i-1] = data.groups[i-1], data.groups[i]
            break
        end
    end
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.move_group_down(unit_number, group_id)
    local data = global.combinator_areas[unit_number]
    if not data or not data.groups then return end
    for i, g in ipairs(data.groups) do
        if g.id == group_id and i < #data.groups then
            data.groups[i], data.groups[i+1] = data.groups[i+1], data.groups[i]
            break
        end
    end
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.set_group_name(unit_number, group_id, name)
    local data = global.combinator_areas[unit_number]
    if not data or not data.groups then return end
    for _, g in ipairs(data.groups) do
        if g.id == group_id then
            g.name = (name ~= "") and name or "Новая группа"
            break
        end
    end
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.set_drone_count(unit_number, group_id, drone_type, value)
    local data = global.combinator_areas[unit_number]
    if not data or not data.groups then return end
    for _, g in ipairs(data.groups) do
        if g.id == group_id then
            if drone_type == "logistic" then
                g.logistic = value
            else
                g.construction = value
            end
            break
        end
    end
    combinator_schedule.sync_drone_counts_for_group(unit_number, group_id)
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.toggle_group(unit_number, group_id)
    local data = global.combinator_areas[unit_number]
    if not data or not data.groups then return end
    for _, g in ipairs(data.groups) do
        if g.id == group_id then
            g.enabled = not g.enabled
            set_group_children_state(unit_number, group_id, g.enabled)
            break
        end
    end
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.delete_area(unit_number, group_id, area_id)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end
    for i, area in ipairs(data.areas[group_id]) do
        if area.id == area_id then
            table.remove(data.areas[group_id], i)
            break
        end
    end
    combinator_schedule.sync_drone_counts_for_group(unit_number, group_id)
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.move_area_up(unit_number, group_id, area_id)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end
    local areas = data.areas[group_id]
    for i, area in ipairs(areas) do
        if area.id == area_id and i > 1 then
            areas[i], areas[i-1] = areas[i-1], areas[i]
            break
        end
    end
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.move_area_down(unit_number, group_id, area_id)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end
    local areas = data.areas[group_id]
    for i, area in ipairs(areas) do
        if area.id == area_id and i < #areas then
            areas[i], areas[i+1] = areas[i+1], areas[i]
            break
        end
    end
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.toggle_area(unit_number, group_id, area_id)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end
    for _, area in ipairs(data.areas[group_id]) do
        if area.id == area_id then
            area.enabled = not area.enabled
            break
        end
    end
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.move_construction_section_up(unit_number, group_id, area_id)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end
    local area = nil
    for _, a in ipairs(data.areas[group_id]) do
        if a.id == area_id then area = a; break end
    end
    if not area then return end
    area.construction_data, area.logistic_data = area.logistic_data, area.construction_data
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.move_construction_section_down(unit_number, group_id, area_id)
    combinator_schedule.move_construction_section_up(unit_number, group_id, area_id)
end

function combinator_schedule.move_logistic_section_up(unit_number, group_id, area_id)
    combinator_schedule.move_construction_section_up(unit_number, group_id, area_id)
end

function combinator_schedule.move_logistic_section_down(unit_number, group_id, area_id)
    combinator_schedule.move_construction_section_up(unit_number, group_id, area_id)
end

function combinator_schedule.toggle_construction_section(unit_number, group_id, area_id)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end
    local area = nil
    for _, a in ipairs(data.areas[group_id]) do
        if a.id == area_id then area = a; break end
    end
    if not area or not area.construction_data then return end
    area.construction_data.enabled = not area.construction_data.enabled
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.toggle_logistic_section(unit_number, group_id, area_id)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end
    local area = nil
    for _, a in ipairs(data.areas[group_id]) do
        if a.id == area_id then area = a; break end
    end
    if not area or not area.logistic_data then return end
    area.logistic_data.enabled = not area.logistic_data.enabled
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.add_item(unit_number, group_id, area_id, section_kind, item_kind)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end
    local area = nil
    for _, a in ipairs(data.areas[group_id]) do
        if a.id == area_id then area = a; break end
    end
    if not area then return end
    local section = (section_kind == "construction") and area.construction_data or area.logistic_data
    if not section then return end
    local items = (item_kind == "task") and section.tasks or section.links
    if not items then return end
    if not global.next_item_id then global.next_item_id = 1 end
    local new_id = global.next_item_id
    global.next_item_id = new_id + 1
    local default_name = (item_kind == "task") and "Новая задача" or "Новая связь"
    local new_item = {
        id = new_id,
        name = default_name,
        enabled = true,
        drone_count = 0
    }
    create_item_with_parent_state(unit_number, group_id, area_id, section_kind, new_item)

    if section_kind == "construction" and item_kind == "task" then
        new_item.construction_objects = {
            { name = "iron-chest", count = 5, visible = true },
            { name = "wooden-chest", count = 3, visible = true },
            { name = "stone-furnace", count = 2, visible = true },
            { name = "assembling-machine-1", count = 1, visible = true }
        }
    end

    table.insert(items, new_item)
    if section.auto_distribute_tasks then
        combinator_schedule.sync_tasks_for_section(unit_number, group_id, area_id, section_kind)
    end
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.delete_item(unit_number, group_id, area_id, section_kind, item_kind, item_id)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end
    local area = nil
    for _, a in ipairs(data.areas[group_id]) do
        if a.id == area_id then area = a; break end
    end
    if not area then return end
    local section = (section_kind == "construction") and area.construction_data or area.logistic_data
    if not section then return end
    local items = (item_kind == "task") and section.tasks or section.links
    if not items then return end
    for i, it in ipairs(items) do
        if it.id == item_id then
            table.remove(items, i)
            break
        end
    end
    if section.auto_distribute_tasks then
        combinator_schedule.sync_tasks_for_section(unit_number, group_id, area_id, section_kind)
    end
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.move_item_up(unit_number, group_id, area_id, section_kind, item_kind, item_id)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end
    local area = nil
    for _, a in ipairs(data.areas[group_id]) do
        if a.id == area_id then area = a; break end
    end
    if not area then return end
    local section = (section_kind == "construction") and area.construction_data or area.logistic_data
    if not section then return end
    local items = (item_kind == "task") and section.tasks or section.links
    if not items then return end
    for i, it in ipairs(items) do
        if it.id == item_id and i > 1 then
            items[i], items[i-1] = items[i-1], items[i]
            break
        end
    end
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.move_item_down(unit_number, group_id, area_id, section_kind, item_kind, item_id)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end
    local area = nil
    for _, a in ipairs(data.areas[group_id]) do
        if a.id == area_id then area = a; break end
    end
    if not area then return end
    local section = (section_kind == "construction") and area.construction_data or area.logistic_data
    if not section then return end
    local items = (item_kind == "task") and section.tasks or section.links
    if not items then return end
    for i, it in ipairs(items) do
        if it.id == item_id and i < #items then
            items[i], items[i+1] = items[i+1], items[i]
            break
        end
    end
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.set_item_name(unit_number, group_id, area_id, section_kind, item_kind, item_id, new_name)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end
    local area = nil
    for _, a in ipairs(data.areas[group_id]) do
        if a.id == area_id then area = a; break end
    end
    if not area then return end
    local section = (section_kind == "construction") and area.construction_data or area.logistic_data
    if not section then return end
    local items = (item_kind == "task") and section.tasks or section.links
    if not items then return end
    for _, it in ipairs(items) do
        if it.id == item_id then
            it.name = (new_name ~= "") and new_name or ((item_kind == "task") and "Новая задача" or "Новая связь")
            break
        end
    end
    combinator_schedule.refresh(unit_number)
end

function combinator_schedule.toggle_item(unit_number, group_id, area_id, section_kind, item_kind, item_id)
    local data = global.combinator_areas[unit_number]
    if not data or not data.areas or not data.areas[group_id] then return end
    local area = nil
    for _, a in ipairs(data.areas[group_id]) do
        if a.id == area_id then area = a; break end
    end
    if not area then return end
    local section = (section_kind == "construction") and area.construction_data or area.logistic_data
    if not section then return end
    local items = (item_kind == "task") and section.tasks or section.links
    if not items then return end
    for _, it in ipairs(items) do
        if it.id == item_id then
            it.enabled = not it.enabled
            break
        end
    end
    combinator_schedule.refresh(unit_number)
end

-- Совместимость со старыми названиями
function combinator_schedule.add_task(unit_number, group_id, area_id, task_kind)
    combinator_schedule.add_item(unit_number, group_id, area_id, task_kind, "task")
end
function combinator_schedule.delete_task(unit_number, group_id, area_id, task_kind, task_id)
    combinator_schedule.delete_item(unit_number, group_id, area_id, task_kind, "task", task_id)
end
function combinator_schedule.move_task_up(unit_number, group_id, area_id, task_kind, task_id)
    combinator_schedule.move_item_up(unit_number, group_id, area_id, task_kind, "task", task_id)
end
function combinator_schedule.move_task_down(unit_number, group_id, area_id, task_kind, task_id)
    combinator_schedule.move_item_down(unit_number, group_id, area_id, task_kind, "task", task_id)
end
function combinator_schedule.set_task_name(unit_number, group_id, area_id, task_kind, task_id, new_name)
    combinator_schedule.set_item_name(unit_number, group_id, area_id, task_kind, "task", task_id, new_name)
end
function combinator_schedule.toggle_task(unit_number, group_id, area_id, task_kind, task_id)
    combinator_schedule.toggle_item(unit_number, group_id, area_id, task_kind, "task", task_id)
end

function combinator_schedule.add_link(unit_number, group_id, area_id, link_kind)
    combinator_schedule.add_item(unit_number, group_id, area_id, link_kind, "link")
end
function combinator_schedule.delete_link(unit_number, group_id, area_id, link_kind, link_id)
    combinator_schedule.delete_item(unit_number, group_id, area_id, link_kind, "link", link_id)
end
function combinator_schedule.move_link_up(unit_number, group_id, area_id, link_kind, link_id)
    combinator_schedule.move_item_up(unit_number, group_id, area_id, link_kind, "link", link_id)
end
function combinator_schedule.move_link_down(unit_number, group_id, area_id, link_kind, link_id)
    combinator_schedule.move_item_down(unit_number, group_id, area_id, link_kind, "link", link_id)
end
function combinator_schedule.set_link_name(unit_number, group_id, area_id, link_kind, link_id, new_name)
    combinator_schedule.set_item_name(unit_number, group_id, area_id, link_kind, "link", link_id, new_name)
end
function combinator_schedule.toggle_link(unit_number, group_id, area_id, link_kind, link_id)
    combinator_schedule.toggle_item(unit_number, group_id, area_id, link_kind, "link", link_id)
end

-- === ОСНОВНАЯ ФУНКЦИЯ ОБНОВЛЕНИЯ GUI (REFRESH) ===
function combinator_schedule.refresh(unit_number)
    local data = global.combinator_areas[unit_number]
    if not data then return end
    local schedule_flow = data.schedule_flow
    if not schedule_flow or not schedule_flow.valid then return end

    schedule_flow.clear()
    schedule_flow.style.vertically_stretchable = false

    local add_group_section = schedule_flow.add({ type = "flow", direction = "vertical" })
    add_group_section.style.width = 392
    add_group_section.style.vertically_stretchable = false

    local groups_container = add_group_section.add({ type = "flow", direction = "vertical" })
    groups_container.style.width = 392
    groups_container.style.margin = {0,0,2,0}
    groups_container.style.horizontal_align = "right"
    groups_container.style.vertically_stretchable = false

    for _, group in ipairs(data.groups) do
        local group_wrapper = groups_container.add({ type = "flow", direction = "vertical" })
        group_wrapper.style.width = 392
        group_wrapper.style.margin = {0,0,2,0}
        group_wrapper.style.horizontal_align = "right"
        group_wrapper.style.vertically_stretchable = false

        create_group_frame(group_wrapper, unit_number, group)

        local add_area_section = group_wrapper.add({ type = "flow", direction = "vertical" })
        add_area_section.style.width = 350
        add_area_section.style.margin = {2,0,0,0}
        add_area_section.style.vertically_stretchable = false

        local areas_container = add_area_section.add({ type = "flow", direction = "vertical" })
        areas_container.style.width = 350
        areas_container.style.horizontal_align = "right"
        areas_container.style.vertically_stretchable = false

        local group_areas = data.areas and data.areas[group.id] or {}
        for _, area in ipairs(group_areas) do
            if area.construction_data and area.construction_data.drone_count == nil then
                area.construction_data.drone_count = 0
            end
            if area.logistic_data and area.logistic_data.drone_count == nil then
                area.logistic_data.drone_count = 0
            end
            if area.construction_data.auto_distribute_tasks == nil then
                area.construction_data.auto_distribute_tasks = true
            end
            if area.logistic_data.auto_distribute_tasks == nil then
                area.logistic_data.auto_distribute_tasks = true
            end

            create_area_frame(areas_container, unit_number, group.id, area)

            local tasks_section_wrapper = areas_container.add({ type = "flow", direction = "vertical" })
            tasks_section_wrapper.style.width = 300
            tasks_section_wrapper.style.horizontal_align = "right"
            tasks_section_wrapper.style.margin = {2,0,0,0}
            tasks_section_wrapper.style.vertically_stretchable = false

            if not area.construction_data then
                area.construction_data = { enabled = true, drone_count = 0, tasks = {}, links = {}, auto_distribute_tasks = true }
            end
            if not area.logistic_data then
                area.logistic_data = { enabled = true, drone_count = 0, tasks = {}, links = {}, auto_distribute_tasks = true }
            end

            create_main_task_section(tasks_section_wrapper, unit_number, group.id, area.id, "construction", area.construction_data, "logistic")
            create_main_task_section(tasks_section_wrapper, unit_number, group.id, area.id, "logistic", area.logistic_data, "construction")
        end

        local add_area_btn = add_area_section.add({
            type = "button",
            name = string.format("combinator_add_area_%d_%d", unit_number, group.id),
            caption = "+ Добавить область",
            style = "button"
        })
        add_area_btn.style.width = 350
        add_area_btn.style.height = 36
        add_area_btn.style.horizontal_align = "left"
        add_area_btn.style.left_padding = 8
        add_area_btn.tags = { unit_number = unit_number, group_id = group.id }
    end

    local add_group_btn = add_group_section.add({
        type = "button",
        name = string.format("combinator_add_group_%d", unit_number),
        caption = "+ Добавить группу",
        style = "button"
    })
    add_group_btn.style.width = 392
    add_group_btn.style.height = 36
    add_group_btn.style.horizontal_align = "left"
    add_group_btn.style.left_padding = 8
    add_group_btn.style.margin = {2,0,0,0}
    add_group_btn.tags = { unit_number = unit_number }
end

return combinator_schedule