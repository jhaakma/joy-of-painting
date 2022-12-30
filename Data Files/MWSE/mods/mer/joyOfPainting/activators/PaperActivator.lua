--[[
    Activate a quill with a piece of paper and inkwell in your inventory to begin sketching
]]
local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("PaperActivator")
local Painting = require("mer.joyOfPainting.items.Painting")
local PhotoMenu = require("mer.joyOfPainting.services.PhotoMenu")

local PaperActivator = {
    name = "PaperActivator",
}

local function paperPaint(reference, artStyleName)
    local painting = Painting:new{
        reference = reference
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
                        scale = painting.reference.scale,
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

---@param e equipEventData|activateEventData
function PaperActivator.activate(e)
    local painting = Painting:new{
        reference = e.target,
        item = e.item, ---@type any
        itemData = e.itemData,
    }
    tes3ui.showMessageMenu{
        message = painting.reference.object.name,
        buttons = {
            {
                text = "Draw/Paint",
                callback = function()
                    local buttons = {}
                    for _, artStyle in pairs(config.artStyles) do
                        if artStyle.requiresEasel ~= true then
                            table.insert(buttons, {
                                text = artStyle.name,
                                callback = function()
                                    paperPaint(painting.reference, artStyle.name)
                                end,
                            })
                        end
                    end
                    tes3ui.showMessageMenu{
                        text = "Select Art Style",
                        buttons = buttons,
                        cancels = true
                    }
                end,
            },
            {
                text = "Pick Up",
                callback = function()
                    common.pickUp(painting.reference)
                end,
            }
        },
        cancels = true
    }
end

return PaperActivator