-- core/utils.lua
local utils = {}

function utils.table_size(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

return utils