local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("TapestryActivator")

local function onActivate(e)
    local reference = e.reference
    if not reference then return end
    if config.tapestries[reference.object.id:lower()] == nil then return end
    if not config.mcm.enableTapestryRemoval then return end
    tes3ui.showMessageMenu{
        message = "Tapestry",
        buttons = {
            {
                text = "Remove",
                callback = function()
                    reference:delete()
                    tes3.playSound{
                        sound = "Item Misc Up",
                    }
                end
            }
        },
        cancels = true
    }
end

event.register("CraftingFramework:StaticActivation", onActivate)