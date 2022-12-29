--[[
    Activate a quill with a piece of paper and inkwell in your inventory to begin sketching
]]
local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("PaintingActivator")
local Painting = require("mer.joyOfPainting.items.Painting")
local PhotoMenu = require("mer.joyOfPainting.services.PhotoMenu")

local function paperPaint(target, artStyleName)
    local painting = Painting:new{
        reference = target
    }
    painting.data.artStyle = artStyleName

    local canvasConfig = painting:getCanvasConfig()
    if canvasConfig then
        timer.delayOneFrame(function()
            PhotoMenu:new{
                canvasConfig = canvasConfig,
                artStyle = config.artStyles[artStyleName],
                captureCallback = function(e)
                    --set paintingTexture before creating object
                    painting.data.paintingTexture = e.paintingTexture
                    painting.data.location = tes3.player.cell.displayName
                    painting:doPaintAnim()
                end,
                cancelCallback = function()
                    logger:debug("Cancelling painting")
                    tes3.messageBox("You scrape the paint from the canvas.")
                    painting:cleanCanvas()
                end,
                finalCallback = function(e)
                    logger:debug("Creating new object for painting %s", e.paintingName)
                    ---@type any
                    local newPaintingObject = painting:createPaintingObject()
                    local newPaper = tes3.createReference{
                        object = newPaintingObject,
                        position = painting.reference.position,
                        orientation = painting.reference.orientation,
                        cell = painting.reference.cell,
                    }
                    newPaper.data.joyOfPainting = {}
                    local paperPainting = Painting:new{
                        reference = newPaper
                    }
                    for _, field in ipairs(Painting.canvasFields) do
                        paperPainting.data[field] = painting.data[field]
                    end
                    paperPainting.data.paintingId = newPaintingObject.id
                    paperPainting.data.canvasId = painting.reference.object.id:lower()
                    paperPainting.data.paintingName = e.paintingName
                    paperPainting:doVisuals()

                    tes3.messageBox("Successfully created %s", newPaintingObject.name)
                    --assert all canvasConfig fields are filled in
                    for _, field in ipairs(Painting.canvasFields) do
                        assert(paperPainting.data[field] ~= nil, string.format("Missing field %s", field))
                    end
                    painting.reference:delete()
                end
            }:open()
        end)
    else
        logger:error("No canvas data found for %s", painting.data.canvasId)
        return
    end
end

local function openPaperMenu(target)
    tes3ui.showMessageMenu{
        message = target.object.name,
        buttons = {
            {
                text = "Draw/Paint",
                callback = function(e)
                    local buttons = {}
                    for _, artStyle in pairs(config.artStyles) do
                        table.insert(buttons, {
                            text = artStyle.name,
                            callback = function()
                                paperPaint(target, artStyle.name)
                            end,
                        })
                    end
                    tes3ui.showMessageMenu{
                        text = "Select Art Style",
                        buttons = buttons
                    }
                end,
            },
            {
                text = "Pick Up",
                callback = function(e)
                    -- Add it to the player's inventory manually.
                    tes3.addItem({
                        reference = tes3.player,
                        item = target.object,
                        count = 1,
                        itemData = target.itemData,
                    })
                    target.itemData = nil
                    target:delete()
                end,
            }
        },
        cancels = true
    }
end


--On activate paper, open paint menu
---@param e activateEventData
local function onActivatePaper(e)
    if tes3ui.menuMode() then return end
    if common.isShiftDown() then return end
    if e.activator ~= tes3.player then return end
    if common.isStack(e.target) then
        logger:debug("%s is stack, skip", e.target.object.id)
        return
    end
    local painting = Painting:new{
        reference = e.target
    }
    local canvasConfig = painting:getCanvasConfig()
    if not canvasConfig then
        return
    end
    if canvasConfig.requiresEasel then
        logger:debug("%s Requires easel, skip", e.target.object.id)
        return
    end
    if painting:hasPaintingData() then
        logger:debug("%s already has painting data, skip", e.target.object.id)
        return
    end
    openPaperMenu(e.target)
    return false
end

event.register("activate", onActivatePaper)
