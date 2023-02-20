local ReferenceManager = require("mer.joyOfPainting.services.ReferenceManager")
local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("ReferenceController")

---@param e referenceSceneNodeCreatedEventData
local function onRefPlaced(e)
    if not e.reference then
        logger:error("Reference is nil")
        return
    end
    local controllers = ReferenceManager.registerReference(e.reference)
    for _, controller in pairs(controllers) do
        if controller.onActive then
            controller:onActive(e.reference)
        end
    end
end
event.register("referenceSceneNodeCreated", onRefPlaced)

local function onObjectInvalidated(e)
    ReferenceManager.invalidate(e)
end
event.register("objectInvalidated", onObjectInvalidated)