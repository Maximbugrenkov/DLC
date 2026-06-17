-- events/on_selection.lua
local area = require("core.area")
local rendering = require("core.rendering")
local area_editor = require("gui.area_editor")
local preview = require("core.preview")

local MARGIN = 5

local LOGISTIC_CHEST_TYPES = {
    ["active-provider-chest"] = true,
    ["passive-provider-chest"] = true,
    ["storage-chest"] = true,
    ["buffer-chest"] = true,
    ["requester-chest"] = true,
}

local function on_player_selected_area(event)
    if event.item ~= "area-creator" then return end
    local player = game.players[event.player_index]
    local player_index = event.player_index
    local area_data = event.area
    local surface = player.surface

    if not global.pending_areas then global.pending_areas = {} end
    if not global.tile_states then global.tile_states = {} end
    if not global.player_main_frames then global.player_main_frames = {} end

    preview.clear()
    if global.pending_areas[player_index] then global.pending_areas[player_index] = nil end
    if global.tile_states[player_index] then global.tile_states[player_index] = nil end
    if global.player_main_frames[player_index] then
        local old_frame = global.player_main_frames[player_index]
        if old_frame and old_frame.valid then old_frame.destroy() end
        global.player_main_frames[player_index] = nil
    end

    local left = area_data.left_top.x
    local top = area_data.left_top.y
    local right = area_data.right_bottom.x
    local bottom = area_data.right_bottom.y

    local tile_min_x = math.floor(left)
    local tile_min_y = math.floor(top)
    local tile_max_x = math.ceil(right) - 1
    local tile_max_y = math.ceil(bottom) - 1

    if tile_max_x < tile_min_x or tile_max_y < tile_min_y then
        player.print("Область слишком мала.")
        return
    end

    local min_x = tile_min_x - MARGIN
    local min_y = tile_min_y - MARGIN
    local max_x = tile_max_x + MARGIN
    local max_y = tile_max_y + MARGIN

    local width = max_x - min_x + 1
    local height = max_y - min_y + 1

    local grid_states = {}
    for row = 1, height do
        grid_states[row] = {}
        for col = 1, width do
            grid_states[row][col] = false
        end
    end

    for x = tile_min_x, tile_max_x do
        for y = tile_min_y, tile_max_y do
            local col = x - min_x + 1
            local row = y - min_y + 1
            if col >= 1 and col <= width and row >= 1 and row <= height then
                grid_states[row][col] = true
            end
        end
    end

    local entity_counts = {}
    local logistic_chests = {}

    for row = 1, height do
        for col = 1, width do
            local world_x = min_x + (col - 1)
            local world_y = min_y + (row - 1)
            local entities = surface.find_entities_filtered{
                area = {{world_x, world_y}, {world_x + 1, world_y + 1}}
            }
            for _, entity in pairs(entities) do
                local name = entity.name
                entity_counts[name] = (entity_counts[name] or 0) + 1
                if LOGISTIC_CHEST_TYPES[name] then
                    table.insert(logistic_chests, {
                        entity = entity,
                        type = name,
                        grid_row = row,
                        grid_col = col,
                        position = entity.position   -- сохраняем позицию
                    })
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

    -- Инициализируем счётчик task_id, если ещё не существует
    if not global.next_task_id then global.next_task_id = 1 end

    local tasks = {}
    local groups = {}
    local next_group_id = 1
    local filter_visibility = {
        active_provider = true,
        passive_provider = true,
        storage = true,
        buffer = true,
        requester = true
    }
    local filter_group_enabled = {
        active_provider = true,
        passive_provider = true,
        storage = true,
        buffer = true,
        requester = true
    }

    local display_order = 1
    for _, chest_data in ipairs(logistic_chests) do
        table.insert(tasks, {
            task_id = global.next_task_id,      -- уникальный идентификатор задачи
            chest_type = chest_data.type,
            position = chest_data.position,   -- позиция сундука
            custom_name = nil,
            enabled = true,
            group_id = nil,
            display_order = display_order,
            grid_row = chest_data.grid_row,
            grid_col = chest_data.grid_col,
        })
        global.next_task_id = global.next_task_id + 1
        display_order = display_order + 1
    end

    global.pending_areas[player_index] = {
        left_top = area_data.left_top,
        right_bottom = area_data.right_bottom,
        margin = MARGIN,
        min_x = min_x, max_x = max_x,
        min_y = min_y, max_y = max_y,
        width = width,
        height = height,
        grid_states = grid_states,
        original_left_top = {x = left, y = top},
        original_right_bottom = {x = right, y = bottom},
        objects = objects_list,
        logistic_chests = logistic_chests,
        tasks = tasks,
        groups = groups,
        next_group_id = next_group_id,
        filter_visibility = filter_visibility,
        filter_group_enabled = filter_group_enabled,
    }

    preview.update_from_pending(player_index)

    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == "area-creator" then
        cursor_stack.clear()
    end

    if player.gui.screen.area_editor_frame then
        player.gui.screen.area_editor_frame.destroy()
    end

    if not global.delayed_window_open then
        global.delayed_window_open = {}
    end
    global.delayed_window_open[player_index] = {
        tick = game.tick + 6,
        player_index = player_index,
        pending = global.pending_areas[player_index]
    }
end

return on_player_selected_area