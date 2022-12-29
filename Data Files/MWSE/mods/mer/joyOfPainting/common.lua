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

return common