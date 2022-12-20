local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("SketchController")

local ArtStyleService = {}

---@param artStyle JoyOfPainting.ArtStyle
function ArtStyleService.playerHasTools(artStyle)
    local player = tes3.player
    if artStyle.tools then
        for _, toolId in ipairs(artStyle.tools) do
            local hasTool = player.object.inventory:contains{item = toolId}
            if not hasTool then
                return false
            end
        end
    end
    return true
end

function ArtStyleService.playerHasPaint(artStyle)
    local player = tes3.player
    --iterate stack, find paint and check itemData.data.paintLevel
    for _, stack in pairs(player.object.inventory) do
        if stack.object.id == artStyle.paintHolder then
            local paintLevel = stack.itemData.data.paintLevel
            if paintLevel and paintLevel > 0 then
                return true
            end
        end
    end
end

function ArtStyleService.getValidArtStyles()

end

return ArtStyleService
