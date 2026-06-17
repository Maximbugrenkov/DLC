-- core/area.lua
local area = {}

-- Вспомогательная функция округления координат до целых клеток
local function round_coords(zone)
    zone.area.x1 = math.floor(zone.area.x1)
    zone.area.y1 = math.floor(zone.area.y1)
    zone.area.x2 = math.ceil(zone.area.x2)
    zone.area.y2 = math.ceil(zone.area.y2)
    return zone
end

-- Создание области по координатам углов, с тайлами и цветом
function area.create(name, priority, left_top, right_bottom, tiles, color)
    local zone = {
        id = global.area_id_counter,
        name = name,
        base_priority = priority,
        dynamic_priority = nil,
        area = {
            x1 = left_top.x,
            y1 = left_top.y,
            x2 = right_bottom.x,
            y2 = right_bottom.y
        },
        tiles = tiles,   -- таблица { [x] = { [y] = true } }
        color = color or {0.2, 0.6, 1, 0.5}
    }
    round_coords(zone)
    global.area_id_counter = global.area_id_counter + 1
    global.areas[zone.id] = zone
    return zone
end

-- Получение текущего приоритета области
function area.get_current_priority(area_id)
    local zone = global.areas[area_id]
    if not zone then return nil end
    return zone.dynamic_priority or zone.base_priority
end

-- Обновление динамического приоритета (для комбинатора)
function area.update_dynamic_priority(area_id, priority)
    local zone = global.areas[area_id]
    if zone then
        zone.dynamic_priority = priority
    end
end

-- Получение области по ID
function area.get_area(area_id)
    return global.areas[area_id]
end

-- Проверка попадания точки в область (с допуском)
local function point_in_area(px, py, zone)
    local eps = 0.5
    return px >= zone.area.x1 - eps and px <= zone.area.x2 + eps and
           py >= zone.area.y1 - eps and py <= zone.area.y2 + eps
end

-- Получение всех областей, содержащих точку
function area.get_areas_at_point(px, py)
    local result = {}
    for id, zone in pairs(global.areas) do
        if point_in_area(px, py, zone) then
            table.insert(result, zone)
        end
    end
    return result
end

-- Удаление области по ID
function area.remove(area_id)
    if global.areas[area_id] then
        global.areas[area_id] = nil
    end
end

-- Очистка всех областей
function area.clear_all()
    global.areas = {}
    global.area_id_counter = 0
end

return area