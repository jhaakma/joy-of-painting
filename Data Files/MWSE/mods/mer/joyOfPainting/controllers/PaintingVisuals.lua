--[[
    Controller for updating the visuals of paintings and easels
]]
local Painting = require("mer.joyOfPainting.items.Painting")
local Easel = require("mer.joyOfPainting.items.Easel")
local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("PaintingVisuals")

local function manageSceneNodeCreated(e)
    --First attach canvas to easel
    local easel = Easel:new(e.reference)
    if easel then
        logger:debug("Updating easel visuals for %s", easel.name)
        easel:doCanvasVisuals()
    end
    --Then add paint
    local paint = Painting:new(e.reference)
    if paint then
        logger:debug("Updating painting visuals for %s", paint.id)
        paint:doPaintingVisuals()
    end
end

event.register("referenceSceneNodeCreated", manageSceneNodeCreated)