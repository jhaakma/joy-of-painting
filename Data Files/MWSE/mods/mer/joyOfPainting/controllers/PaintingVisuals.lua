--[[
    Controller for updating the visuals of paintings and easels
]]
local Painting = require("mer.joyOfPainting.items.Painting")
local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("PaintingVisuals")

---@param e referenceSceneNodeCreatedEventData
local function manageSceneNodeCreated(e)
    local painting =  Painting:new{
        reference = e.reference
    }
    --Attach canvas then add paint to canvas
    if painting:hasCanvasData() then
        painting:doVisuals()
    end
end

event.register("referenceSceneNodeCreated", manageSceneNodeCreated)

--- @param e meshLoadEventData
local function manageMeshLoad(e)
    --logger:debug(e.path)
    local override = config.meshOverrides[e.path:lower()]
    if override then
        logger:debug("Overriding mesh %s with %s", e.path, override)
        e.path = override
    end
end
event.register("meshLoad", manageMeshLoad)