local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("FrameActivator")
local Painting = require("mer.joyOfPainting.items.Painting")
local UIHelper = require("mer.joyOfPainting.services.UIHelper")


--[[
    Menu options:
    Add Painting
    Remove Painting
    View Painting
    Take Frame
    Cancel
]]
local skipActivate = false
---@param e activateEventData
local function openFrameMenu(e)
    local painting = Painting:new{
        reference = e.target
    }
    local hasCanvas = painting:hasCanvasData()
    local isPainted = painting:hasPaintingData()
    local safeRef = tes3.makeSafeObjectHandle(e.target)
    local frameConfig = config.frames[e.target.object.id:lower()]
    if safeRef == nil then
        logger:warn("Failed to make safe handle for %s", e.target.object.id)
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
                            title = "Select a painting",
                            noResultsText = "No canvases found",
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
                                local painting = Painting:new{
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
                            noResultsCallback = function()
                                tes3.messageBox("You don't have any canvases in your inventory.")
                            end
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
                        local painting = Painting:new{
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
                        skipActivate = true
                        painting = Painting:new{
                            reference = ref
                        }
                        painting:takeCanvas()
                        tes3.player:activate(ref)
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


---@param e activateEventData
local function onActivate(e)
    if skipActivate then
        skipActivate = false
        return
    end
    logger:debug("Frame onActivate")
    if tes3ui.menuMode() then return end
    if common.isShiftDown() then return end
    if common.isStack(e.target) then
        logger:debug("%s is stack, skip", e.target.object.id)
        return
    end
    --check if registered frame
    local id = e.target.object.id:lower()
    local isFrame = config.frames[id]
    if not isFrame then
        logger:debug("%s is not a frame", id)
        return
    end
    logger:debug("Frame activated: %s", id)
    openFrameMenu(e)
    --block activate
    return false
end

event.register(tes3.event.activate, onActivate)