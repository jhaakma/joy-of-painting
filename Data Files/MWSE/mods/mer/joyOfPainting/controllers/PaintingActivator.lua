local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Tooltips")
local Painting = require("mer.joyOfPainting.items.Painting")
local UIHelper = require("mer.joyOfPainting.services.UIHelper")

---@param e equipEventData
local function clearCanvas(e)
    logger:debug("Clearing painting data")
    if config.frames[e.item.id:lower()] then
        e.itemData.data.joyOfPainting.paintingTexture = nil
        e.itemData.data.joyOfPainting.paintingName = nil
        e.itemData.data.joyOfPainting.paintingId = nil
    else
        tes3.addItem{
            item = e.itemData.data.joyOfPainting.canvasId,
            count = 1,
            reference = tes3.player,
            playSound = false,
        }
        tes3.removeItem{
            item = e.item.id,
            itemData = e.itemData,
            count = 1,
            reference = tes3.player,
            playSound = false,
        }
    end
end

---@param e equipEventData
local function onEquip(e)
    local isPainting = Painting.hasPaintingData(e.itemData)
    if isPainting then
        logger:debug("Canvas Activated")
        local paintingData = e.itemData.data.joyOfPainting
        local paintingTexture = paintingData.paintingTexture
        local tooltipText = string.format("Location: %s.", paintingData.location)
        local paintingName = paintingData.paintingName or e.item.name
        local tooltipHeader = paintingName
        logger:debug("Painting Name: %s", paintingName)
        local dataHolder = paintingData
        UIHelper.openPaintingMenu{
            canvasId = paintingData.canvasId,
            paintingTexture = paintingTexture,
            tooltipHeader = tooltipHeader,
            tooltipText = tooltipText,
            dataHolder = dataHolder,
            callback = function()
                tes3.messageBox("Renamed to '%s'", dataHolder.paintingName)
                if not config.frames[e.item.id:lower()] then
                    e.item.name = dataHolder.paintingName
                end
            end,
            buttons = {
                {
                    text = "Scrape",
                    callback = function()
                        UIHelper.scrapePaintingMessage(function()
                            clearCanvas(e)
                        end)
                    end,
                    closesMenu = true
                },
            }
        }
    end
end
event.register(tes3.event.equip, onEquip)