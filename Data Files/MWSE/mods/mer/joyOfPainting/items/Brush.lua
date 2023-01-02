local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Brush")

local Brush = {
    classname = "Brush",
}
---@class JOP.BrushType
---@field id string The id of the brush type
---@field name string The name of the brush type

---@param e JOP.BrushType
function Brush.registerBrushType(e)
    common.logAssert(logger, type(e.id) == "string", "id must be a string")
    common.logAssert(logger, type(e.name) == "string", "name must be a string")
    logger:debug("Registering brush type %s", e.id)
    e.id = e.id:lower()
    config.brushTypes[e.id] = table.copy(e, {})
end

---@class JOP.Brush
---@field id string The id of the brush
---@field brushType string The brush type to use for this brush

---@param e JOP.Brush
function Brush.registerBrush(e)
    common.logAssert(logger, type(e.id) == "string", "id must be a string")
    common.logAssert(logger, type(e.brushType) == "string", "brushTypes must be a string")
    logger:debug("Registering brush %s", e.id)
    e.id = e.id:lower()
    config.brushes[e.id] = table.copy(e, {})
end

return Brush