local NodeManager = require("mer.joyOfPainting.services.NodeManager")
local Palette = require("mer.joyOfPainting.items.Palette")
---@type JOP.Switch[]
local switches = {
    {
        id = "paint_palette",
        switchName = "SWITCH_PALETTE_PAINT",
        getActiveNode = function(e)
            local palette = Palette:new{reference = e.reference}
            local hasPaint = palette:getRemainingUses() > 0
            return hasPaint and "ON" or "OFF"
        end,
    }
}

for _, switch in ipairs(switches) do
    NodeManager.registerSwitch(switch)
end