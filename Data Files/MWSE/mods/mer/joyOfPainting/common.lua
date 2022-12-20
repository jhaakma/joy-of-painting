local common = {}

local config = require("mer.joyOfPainting.config")
local MWSELogger = require("logging.logger")

---@type table<string, MWSELogger>
common.loggers = {}

common.createLogger = function(serviceName)
    local logger = MWSELogger.new{
        name = string.format("JoyOfPainting - %s", serviceName),
        logLevel = config.mcm.logLevel
    }
    common.loggers[serviceName] = logger
    return logger
end

return common