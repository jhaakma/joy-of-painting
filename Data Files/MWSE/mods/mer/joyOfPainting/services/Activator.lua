local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Activator")

local Activator = {
    ---@type JoyOfPainting.Activator[]
    activators = {}
}

---@class JoyOfPainting.Activator.callbackParams
---@field target tes3reference?
---@field item tes3item?
---@field itemData tes3itemData?

---@class JoyOfPainting.Activator
---@field onActivate function
---@field onPickup function
---@field isActivatorItem function
---@field blockStackActivate boolean

---@param activator JoyOfPainting.Activator
function Activator.registerActivator(activator)
    common.logAssert(logger, type(activator.onActivate) == "function", "onActivate must be a function")
    common.logAssert(logger, type(activator.isActivatorItem) == "function", "isActivatorItem must be a function")
    table.insert(Activator.activators, activator)
end

---@param e activateEventData
function Activator.doBlockActivate(e)
    if e.activator ~= tes3.player then
        logger:debug("Not player, skip")
        return true
    end

    return false
end

return Activator