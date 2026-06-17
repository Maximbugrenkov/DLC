-- utils/task_utils.lua
local task_utils = {}

-- Возвращает описание текущего действия сундука (краткая строка)
function task_utils.get_chest_status_text(entity)
    if not entity or not entity.valid then
        return "Недоступен"
    end

    local chest_type = entity.name
    local inventory = entity.get_inventory(defines.inventory.chest)

    if not inventory then
        return "Нет данных"
    end

    -- Для реквестора и буфера показываем запросы
    if chest_type == "requester-chest" or chest_type == "buffer-chest" then
        local requests = {}
        local request_slots = entity.request_slot_count or 0
        for i = 1, request_slots do
            local req = entity.get_request_slot(i)
            if req and req.name then
                table.insert(requests, req.name)
            end
        end
        if #requests > 0 then
            return "Ожидает: " .. table.concat(requests, ", ")
        else
            return "Нет запросов"
        end
    end

    -- Для провайдеров и склада показываем суммарное количество предметов
    local total_items = 0
    local contents = inventory.get_contents()
    for item_name, count in pairs(contents) do
        if type(count) == "number" then
            total_items = total_items + count
        end
    end

    if total_items == 0 then
        return "Пусто"
    else
        return "Хранит: " .. tostring(total_items) .. " шт."
    end
end

-- Возвращает список содержимого сундука как массив строк
function task_utils.get_chest_contents_list(entity)
    local list = {}
    if not entity or not entity.valid then return list end
    local inventory = entity.get_inventory(defines.inventory.chest)
    if not inventory then return list end

    local contents = inventory.get_contents()
    for item_name, count in pairs(contents) do
        if type(count) == "number" then
            table.insert(list, item_name .. ": " .. tostring(count))
        else
            table.insert(list, item_name .. ": ?")
        end
    end
    return list
end

return task_utils