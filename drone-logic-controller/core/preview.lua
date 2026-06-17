-- core/preview.lua
local preview = {}

local current_preview_renders = {}

-- Отрисовка предпросмотра по переданным тайлам
function preview.draw(tiles, color)
    preview.clear()
    
    if not tiles or not next(tiles) then
        return
    end
    
    local surface = game.surfaces[1]
    if not surface then return end
    
    color = color or {0.2, 0.8, 0.4, 0.5}
    
    local new_renders = {}
    for x, ys in pairs(tiles) do
        for y, _ in pairs(ys) do
            local rect = rendering.draw_rectangle{
                surface = surface,
                left_top = {x, y},
                right_bottom = {x + 1, y + 1},
                color = color,
                filled = true,
                players = nil,
                only_in_bounds = true
            }
            table.insert(new_renders, rect)
        end
    end
    
    current_preview_renders = new_renders
end

-- Очистка предпросмотра
function preview.clear()
    for _, render_id in pairs(current_preview_renders) do
        if render_id then
            pcall(render_id.destroy, render_id)
        end
    end
    current_preview_renders = {}
end

-- Обновить предпросмотр по данным из pending
function preview.update_from_pending(player_index)
    local pending = global.pending_areas and global.pending_areas[player_index]
    if not pending then
        preview.clear()
        return
    end
    
    local tiles = {}
    for row = 1, pending.height do
        for col = 1, pending.width do
            if pending.grid_states[row][col] then
                local world_x = pending.min_x + (col - 1)
                local world_y = pending.min_y + (row - 1)
                if not tiles[world_x] then tiles[world_x] = {} end
                tiles[world_x][world_y] = true
            end
        end
    end
    
    preview.draw(tiles, {0.3, 0.8, 0.4, 0.6})
end

return preview