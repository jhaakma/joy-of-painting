local common = {}

local config = require("mer.joyOfPainting.config")
local MWSELogger = require("logging.logger")

---@type table<string, MWSELogger>
common.loggers = {}

function common.createLogger(serviceName)
    local logger = MWSELogger.new{
        name = string.format("JoyOfPainting - %s", serviceName),
        logLevel = config.mcm.logLevel
    }
    common.loggers[serviceName] = logger
    return logger
end

---@param reference tes3reference
---@return boolean
function common.isStack(reference)
    return (
        reference.attachments and
        reference.attachments.variables and
        reference.attachments.variables.count > 1
    )
end

function common.isShiftDown()
    return tes3.worldController.inputController:isKeyDown(tes3.scanCode.lShift)
end

---@param target tes3reference
function common.pickUp(target)
    tes3.addItem({
        reference = tes3.player,
        item = target.object,
        count = 1,
        itemData = target.itemData,
    })
    target.itemData = nil
    target:delete()
end

return common