-- core/init.lua
local function init_global()
    if not global then
        global = {}
    end
    if not global.areas then
        global.areas = {}
    end
    if not global.area_id_counter then
        global.area_id_counter = 0
    end
    if not global.area_rendering then
        global.area_rendering = {}
    end
    if not global.combinators then
        global.combinators = {}
    end
    if not global.pending_areas then
        global.pending_areas = {}
    end
    if not global.delayed_window_open then
        global.delayed_window_open = {}
    end
    if not global.combinator_groups then
        global.combinator_groups = {}
    end
    if not global.combinator_group_id_counter then
        global.combinator_group_id_counter = 1
    end
end

return { init_global = init_global }