local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local DependencyManager = require("mer.joyOfPainting.services.DependencyManager")
local dependencyManager = DependencyManager.new{
    modName = config.modName,
    dependencies = config.dependencies,
    logger = common.createLogger("DependencyManager"),
}
local function onLoaded()
    dependencyManager:checkDependencies()
end

event.register("loaded", onLoaded)