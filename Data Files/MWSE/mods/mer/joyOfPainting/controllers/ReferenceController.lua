local ReferenceManager = require("mer.joyOfPainting.services.ReferenceManager")

local function onRefPlaced(e)
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