local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("FrameActivator")
local Painting = require("mer.joyOfPainting.items.Painting")

local FrameActivator = {
    name = "FrameActivator",
}
--[[
    Menu options:
    Add Painting
    Remove Painting
    View Painting
    Take Frame
    Cancel
]]

---@param e equipEventData|activateEventData
function FrameActivator.activate(e)

    local painting = Painting:new{
        reference = e.target,
        item = e.item, ---@type any
        itemData = e.itemData,
    }

    local hasCanvas = painting:hasCanvasData()
    local isPainted = painting:hasPaintingData()
    local safeRef = tes3.makeSafeObjectHandle(painting.reference)
    local frameConfig = config.frames[painting.reference.object.id:lower()]
    if safeRef == nil then
        logger:warn("Failed to make safe handle for %s", painting.reference.object.id)
    end
    tes3ui.showMessageMenu{
        message = "Frame Menu",
        buttons = {
            {
                text = "Add Painting",
                callback = function()
                    timer.delayOneFrame(function()
                        if not safeRef:valid() then
                            logger:warn("Skipping add painting because reference is invalid")
                            return
                        end

                        local ref = safeRef:getObject()

                        logger:debug("Add Painting")
                        tes3ui.showInventorySelectMenu{
                            title = "Select Painting",
                            noResultsText = "You don't have any paintings in your inventory.",
                            filter = function(e2)
                                local id = e2.item.id:lower()
                                local painting = Painting:new{
                                    item = e2.item,
                                    itemData = e2.itemData
                                }
                                if not painting:hasPaintingData() then
                                    return false
                                end
                                local canvasConfig = painting:getCanvasConfig()
                                local isFrame = config.frames[id]
                                if isFrame then
                                    logger:debug("Filtering on frame: %s", id)
                                    return false
                                end
                                if frameConfig.frameSize then
                                    logger:debug("Filtering on frame size: %s", frameConfig.frameSize)
                                    if canvasConfig and frameConfig.frameSize ~= canvasConfig.frameSize then
                                        logger:debug("Frame size does not match( %s ~= %s)",
                                            frameConfig.frameSize, canvasConfig.frameSize)
                                        return false
                                    end
                                end
                                if canvasConfig == nil then
                                    return false
                                end
                                logger:debug("Filtering on canvas: %s", id)
                                logger:debug("Frame Size = %s", frameConfig.frameSize)
                                logger:debug("canvas frame size: %s", canvasConfig.frameSize)
                                return true
                            end,
                            callback = function(e2)
                                if not e2.item then return end
                                painting = Painting:new{
                                    reference = ref---@type any
                                }
                                painting:attachCanvas(e2.item, e2.itemData)
                                --Remove the canvas from the player's inventory
                                logger:debug("Removing canvas %s from inventory", e2.item.id)
                                tes3.removeItem{
                                    reference = tes3.player,
                                    item = e2.item.id,
                                    itemData = e2.itemData,
                                    count = 1,
                                    playSound = false,
                                }
                            end,
                        }
                    end)
                end,
                showRequirements = function()
                    return not hasCanvas
                end,
            },
            {
                text = "Remove Painting",
                callback = function()
                    timer.delayOneFrame(function()
                        if not safeRef:valid() then
                            logger:warn("Skipping remove painting because reference is invalid")
                            return
                        end
                        local ref = safeRef:getObject()

                        logger:debug("Remove Painting")
                        painting = Painting:new{
                            reference = ref---@type any
                        }
                        painting:takeCanvas()
                    end)
                end,
                showRequirements = function()
                    return hasCanvas
                end,
            },
            {
                text = "View Painting",
                callback = function()
                    timer.delayOneFrame(function()
                        if not safeRef:valid() then
                            logger:warn("Skipping view painting because reference is invalid")
                            return
                        end
                        Painting:new{
                            reference = safeRef:getObject()---@type any
                        }:paintingMenu()
                    end)
                end,
                showRequirements = function()
                    return isPainted
                end,
            },
            {
                text = "Take Frame",
                callback = function()
                    timer.delayOneFrame(function()
                        if not safeRef:valid() then
                            logger:warn("Skipping take frame because reference is invalid")
                            return
                        end
                        ---@type tes3reference
                        ---@diagnostic disable-next-line: assign-type-mismatch
                        local ref = safeRef:getObject()

                        logger:debug("Take Frame")
                        painting = Painting:new{
                            reference = ref
                        }
                        painting:takeCanvas()
                        common.pickUp(ref)
                    end)
                end,
            },
            {
                text = "Cancel",
                callback = function()
                    logger:debug("Cancel")
                end,
            },
        },
    }
end

return FrameActivator