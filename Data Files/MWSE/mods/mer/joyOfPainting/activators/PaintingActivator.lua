local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("PaintingActivator")
local Painting = require("mer.joyOfPainting.items.Painting")
local Activator = require("mer.joyOfPainting.services.Activator")

---@param e equipEventData|activateEventData
local function activate(e)
    local painting = Painting:new{
        reference = e.target,
        item = e.item,
        itemData = e.itemData,
    }
    tes3ui.showMessageMenu{
        message = painting.item.name,
        buttons = {
            {
                text = "View",
                callback = function()
                    painting:paintingMenu()
                end,
                showRequirements = function()
                    return painting:hasPaintingData()
                end
            },
            {
                text = "Rotate",
                callback = function()
                    painting:rotate()
                end,
                showRequirements = function()
                    return painting:isRotatable()
                end
            },
            {
                text = "Pick Up",
                callback = function()
                    common.pickUp(painting.reference)
                end,
                showRequirements = function()
                    if painting.reference then
                        return true
                    end
                    return false
                end
            },
            {
                text = "Discard",
                callback = function()
                    tes3ui.showMessageMenu{
                        message = string.format("Are you sure you want to discard %s?", painting.item.name),
                        buttons = {
                            {
                                text = "Yes",
                                callback = function()
                                    if painting.reference then
                                        painting.reference:delete()
                                    else
                                        tes3.removeItem{
                                            reference = tes3.player,
                                            item = painting.item,
                                            itemData = painting.dataHolder,
                                            playSound = false,
                                        }
                                    end
                                    tes3.messageBox("You discard %s", painting.item.name)
                                    tes3.playSound{ sound = "scroll"}
                                end,
                            },
                        },
                        cancels = true
                    }
                end,
                showRequirements = function()
                    local canvasConfig = painting:getCanvasConfig()
                    if canvasConfig and not canvasConfig.requiresEasel then
                        return true
                    end
                    return false
                end
            },
        },
        cancels = true
    }
end

Activator.registerActivator{
    onActivate = activate,
    isActivatorItem = function(e)
        local painting = Painting:new{
            reference = e.target,
            item = e.item,
            itemData = e.itemData,
        }

        return painting:isCanvas()
            and ( painting:hasPaintingData()
            or painting:isRotatable())
    end
}