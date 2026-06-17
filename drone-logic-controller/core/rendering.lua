-- core/rendering.lua
local draw = {}

function draw.draw_zone(zone)
    if not zone or not zone.tiles or not zone.id then
        log("DLCP: попытка нарисовать некорректную область")
        return
    end

    -- Удаляем старую визуализацию
    if global.area_rendering[zone.id] then
        for _, render_id in pairs(global.area_rendering[zone.id]) do
            if render_id and render_id.valid then
                render_id.destroy()
            elseif render_id and type(render_id) == "table" and render_id.destroy then
                -- старый формат (число) – игнорируем
                pcall(render_id.destroy, render_id)
            end
        end
        global.area_rendering[zone.id] = nil
    end

    local surface = game.surfaces[1]
    local color = zone.color or {0.2, 0.6, 1, 0.5}
    local new_renders = {}

    for x, ys in pairs(zone.tiles) do
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

    if zone.area then
        local outline = rendering.draw_rectangle{
            surface = surface,
            left_top = {zone.area.x1, zone.area.y1},
            right_bottom = {zone.area.x2, zone.area.y2},
            color = {0.5, 0.6, 0.8, 1},
            filled = false,
            width = 1,
            players = nil,
            only_in_bounds = true
        }
        table.insert(new_renders, outline)
    end

    global.area_rendering[zone.id] = new_renders
end

function draw.erase_zone(area_id)
    if global.area_rendering and global.area_rendering[area_id] then
        for _, render_id in pairs(global.area_rendering[area_id]) do
            if render_id and render_id.valid then
                render_id.destroy()
            else
                pcall(render_id.destroy, render_id)
            end
        end
        global.area_rendering[area_id] = nil
    end
end

function draw.redraw_all()
    for _, renders in pairs(global.area_rendering or {}) do
        if renders then
            for _, render_id in pairs(renders) do
                if render_id and render_id.valid then
                    render_id.destroy()
                else
                    pcall(render_id.destroy, render_id)
                end
            end
        end
    end
    global.area_rendering = {}

    for _, zone in pairs(global.areas or {}) do
        draw.draw_zone(zone)
    end
end

return draw