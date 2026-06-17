-- combinators/controller.lua
local combinator = {}

local get_area, update_area_priority

function combinator.init(deps)
    get_area = deps.get_area
    update_area_priority = deps.update_area_priority
end

function combinator.on_built(event)
    local entity = event.created_entity or event.entity
    if not entity or entity.name ~= "drone-logic-controller" then return end

    -- При создании комбинатор пока не привязан
    global.combinators[entity.unit_number] = {
        entity = entity,
        area_id = nil,
        condition = nil,
        true_priority = 100,
        false_priority = nil,
        last_result = false
    }
end

function combinator.on_destroyed(event)
    local entity = event.entity
    if not entity or entity.name ~= "drone-logic-controller" then return end

    local data = global.combinators[entity.unit_number]
    if data and data.area_id then
        update_area_priority(data.area_id, nil)
    end
    global.combinators[entity.unit_number] = nil
end

local function evaluate_condition(combinator_data)
    local entity = combinator_data.entity
    if not entity.valid then return false end

    local condition = combinator_data.condition
    if not condition then return false end

    local red = entity.get_circuit_network(defines.wire_type.red)
    local green = entity.get_circuit_network(defines.wire_type.green)
    local signals = {}
    if red then
        for _, sig in pairs(red.signals) do
            signals[sig.signal.name] = (signals[sig.signal.name] or 0) + sig.count
        end
    end
    if green then
        for _, sig in pairs(green.signals) do
            signals[sig.signal.name] = (signals[sig.signal.name] or 0) + sig.count
        end
    end

    local value = signals[condition.signal] or 0
    if condition.operator == "<" then
        return value < condition.value
    elseif condition.operator == ">" then
        return value > condition.value
    elseif condition.operator == "=" then
        return value == condition.value
    elseif condition.operator == "<=" then
        return value <= condition.value
    elseif condition.operator == ">=" then
        return value >= condition.value
    else
        return false
    end
end

function combinator.update_all()
    for unit_number, data in pairs(global.combinators) do
        if data.entity.valid then
            local result = evaluate_condition(data)
            if result ~= data.last_result then
                data.last_result = result
                if data.area_id then
                    local priority = result and data.true_priority or data.false_priority
                    update_area_priority(data.area_id, priority)
                end
            end
        else
            global.combinators[unit_number] = nil
        end
    end
end

return combinator