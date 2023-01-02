local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("PaletteActivator")
local Activator = require("mer.joyOfPainting.services.Activator")


local function activate(e)

end

Activator.registerActivator{
    onACtivate = activate,
    isActivatorItem = function(e)
        return config.paletteItems[e.object.id:lower()] ~= nil
    end
}