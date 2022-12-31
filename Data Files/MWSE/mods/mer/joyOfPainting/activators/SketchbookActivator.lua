local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("SketchbookActivator")
local Sketchbook = require("mer.joyOfPainting.items.Sketchbook")

local SketchbookActivator = {
    name = "SketchbookActivator",
}

---@param e equipEventData|activateEventData
function SketchbookActivator.activate(e)
    logger:debug("Activating sketchbook")
    local reference = e.target
    local item
    local itemData
    if not e.target then
        item = e.item
        itemData = e.itemData
    end
    local sketchbook = Sketchbook:new{
        reference = reference,
        item = item,
        itemData = itemData,
    }
    sketchbook:activate()
end

return SketchbookActivator
