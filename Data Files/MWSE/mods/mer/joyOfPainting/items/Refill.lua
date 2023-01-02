local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Refill")

---@class JOP.Refill
---@field paintType string The paint type to refill
---@field requiredItems string[] A list of items needed to perform a refill

local Refill = {}

---@param e JOP.Refill
function Refill.registerRefill(e)
    common.logAssert(logger, type(e.paintType) == "string", "paintType must be a string")
    common.logAssert(logger, type(e.requiredItems) == "table", "requiredItems must be a table")
    logger:debug("Registering refill %s", e.paintType)

    if not config.refills[e.paintType] then
        config.refills[e.paintType] = {}
    end
    table.insert(config.refills[e.paintType], e)
end

return Refill
