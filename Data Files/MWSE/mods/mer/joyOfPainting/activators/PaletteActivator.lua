local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("PaletteActivator")
local Activator = require("mer.joyOfPainting.services.Activator")
local Palette = require("mer.joyOfPainting.items.Palette")

local function activate(e)
    logger:debug("Activating palette")
    local palette = Palette:new{
        reference = e.target,
        item = e.item,
        itemData = e.itemData,
    }
    if palette == nil then
        logger:error("Palette is nil")
        return
    end
    local refills = palette:getRefills()
    if not refills then
        logger:warn("No refills found for palette %s", palette and palette.item.id)
        return
    end

    tes3ui.showMessageMenu{
        message = palette.item.name,
        buttons = {
            {
                text = "Refill",
                callback = function()
                    palette:doRefill()
                end,
                enableRequirements = function()
                    return palette:playerHasRefills()
                        and (palette:getRemainingUses() < palette:getMaxUses())
                end,
                tooltipDisabled = function()
                    if not palette:playerHasRefills() then
                        local paintType = config.paintTypes[palette.paletteItem.paintType]
                        local paintName = paintType.name
                        return { text = string.format("You don't have the required %s.", paintName) }
                    end
                    if not (palette:getRemainingUses() < palette:getMaxUses()) then
                        return { text = "This palette is already full." }
                    end
                end
            },
            {
                text = "Pick Up",
                callback = function()
                    common.pickUp(palette.reference)
                end,
                showRequirements = function()
                    if palette.reference then
                        return true
                    end
                    return false
                end
            }
        },
        cancels = true
    }

end

Activator.registerActivator{
    onActivate = activate,
    isActivatorItem = function(e)
        if tes3ui.menuMode() then
            logger:debug("Menu mode, skip")
            return false
        end
        local palette = Palette:new{
            reference = e.target,
            item = e.item,
            itemData = e.itemData,
        }
        return palette and (palette:getRefills() ~= nil)
    end
}