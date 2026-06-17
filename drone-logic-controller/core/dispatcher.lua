-- core/dispatcher.lua
local dispatcher = {}

local get_areas_at_point

function dispatcher.init(deps)
    get_areas_at_point = deps.get_areas_at_point
end

-- Сбор всех призраков и подсчёт по областям
function dispatcher.evaluate()
    local surface = game.surfaces[1]
    local ghosts = surface.find_entities_filtered{ghost = true}

    if #ghosts == 0 then return end

    local area_stats = {}
    for _, ghost in pairs(ghosts) do
        local pos = ghost.position
        local areas = get_areas_at_point(pos.x, pos.y)
        for _, area in pairs(areas) do
            area_stats[area.id] = (area_stats[area.id] or 0) + 1
        end
    end

    if next(area_stats) then
        local msg = "Статистика призраков по областям:\n"
        for area_id, count in pairs(area_stats) do
            local area = global.areas[area_id]
            if area then
                msg = msg .. string.format("  Область '%s' (ID %d, приор. %d): %d призраков\n",
                    area.name, area_id, area.base_priority, count)
            end
        end
        for _, player in pairs(game.players) do
            player.print(msg)
        end
    end
end

return dispatcher