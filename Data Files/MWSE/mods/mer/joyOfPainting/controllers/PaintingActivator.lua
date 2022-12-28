local Painting = require("mer.joyOfPainting.items.Painting")
---@param e equipEventData
event.register(tes3.event.equip, function(e)
    local isPainting = Painting.hasPaintingData(e.itemData)
    if isPainting then
        Painting.paintingMenu(e.item, e.itemData)
        return false
    end
end)

-- event.register(tes3.event.activate, function(e)
--     local isPainting = Painting.hasPaintingData(e.target)
--     if isPainting then
--         Painting.paintingMenu(e.target.object, e.target)
--         return false
--     end
-- end)