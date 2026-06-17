-- events/gui/task_handlers.lua
local area_editor = require("gui.area_editor")
local helpers = require("utils.gui_helpers")

local task_handlers = {}

function task_handlers.handle(element, player, player_index)
    if element.name and element.name:find("^task_toggle_button_") then
        local task_id = tonumber(string.match(element.name, "%d+"))
        local p_index = element.tags.player_index
        local pending = global.pending_areas[p_index]
        if pending and pending.tasks then
            local task = helpers.find_task_by_id(pending.tasks, task_id)
            if task then
                task.enabled = not task.enabled
                local new_sprite = task.enabled and "utility/play" or "utility/stop"
                element.sprite = new_sprite
                element.tooltip = task.enabled and "Задача активна" or "Задача отключена"
                area_editor.refresh_tasks_frame(p_index)
            end
        end
        return true
    end
    return false
end

return {
    handle = task_handlers.handle,
    on_gui_value_changed = function() end,
    on_gui_confirmed = function() end
}