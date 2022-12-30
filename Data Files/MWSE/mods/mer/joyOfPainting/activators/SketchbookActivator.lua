local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("SketchbookActivator")
local Sketchbook = require("mer.joyOfPainting.items.Sketchbook")

local SketchbookActivator = {
    name = "SketchbookActivator",
}

---@param e equipEventData|activateEventData
function SketchbookActivator.activate(e)
    local sketchbook = Sketchbook:new{
        reference = e.target,
        item = e.item,
        itemData = e.itemData,
    }
    sketchbook:open()
end

return SketchbookActivator
