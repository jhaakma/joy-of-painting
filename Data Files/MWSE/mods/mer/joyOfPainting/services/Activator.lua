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
---@field isActivatorItem function
---@field blockStackActivate boolean

---@param activator JoyOfPainting.Activator
function Activator.registerActivator(activator)
    table.insert(Activator.activators, activator)
end

---@param e activateEventData
function Activator.doBlockActivate(e)
    if tes3ui.menuMode() then
        logger:debug("Menu mode, skip")
        return true
    end
    if common.isShiftDown() then return true end
    if e.activator ~= tes3.player then
        logger:debug("Not player, skip")
        return true
    end

    return false
end

return Activator