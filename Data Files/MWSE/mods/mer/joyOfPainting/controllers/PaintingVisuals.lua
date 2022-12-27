--[[
    Controller for updating the visuals of paintings and easels
]]
local Painting = require("mer.joyOfPainting.items.Painting")
local Easel = require("mer.joyOfPainting.items.Easel")
local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("PaintingVisuals")

local function manageSceneNodeCreated(e)
    --Attach canvas then add paint to canvas
    if Painting.hasCanvasData(e.reference) then
        local paint = Painting:new(e.reference)
        if paint then
            paint:doVisuals()
        end
    end
end

event.register("referenceSceneNodeCreated", manageSceneNodeCreated)