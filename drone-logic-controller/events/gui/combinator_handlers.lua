-- events/gui/combinator_handlers.lua
local combinator_schedule = require("gui.combinator_schedule")

local function handle(element, player, player_index)
    if element.name and element.name:find("^combinator_close_schedule_") then
        local unit_number = tonumber(element.tags.unit_number)
        local frame = player.gui.screen["combinator_schedule_" .. unit_number]
        if frame then frame.destroy(); player.opened = nil end
        return true
    end
    return false
end

return { handle = handle, on_gui_value_changed = function() end, on_gui_confirmed = function() end }