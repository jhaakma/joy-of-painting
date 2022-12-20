local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("Tooltips")
local Easel = require("mer.joyOfPainting.items.Easel")
local UIHelper = require("mer.joyOfPainting.services.UIHelper")

---@param e equipEventData
local function clearCanvas(e)
    logger:debug("Clearing painting data")
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

---@param e equipEventData
local function onEquip(e)
    local isPainting = Easel.isPainting(e)
    if isPainting then
        logger:debug("Canvas Activated")
        local paintingData = e.itemData.data.joyOfPainting
        local paintingTexture = paintingData.paintingTexture
        local tooltipHeader = e.item.name
        local tooltipText = string.format("Location: %s.", paintingData.location)
        local dataHolder = { paintingName = e.item.name:gsub("Painting: ", "") }
        UIHelper.openPaintingMenu{
            canvasId = paintingData.canvasId,
            paintingTexture = paintingTexture,
            tooltipHeader = tooltipHeader,
            tooltipText = tooltipText,
            dataHolder = dataHolder,
            callback = function()
                tes3.messageBox("Renamed to '%s'", dataHolder.paintingName)
                e.item.name = dataHolder.paintingName
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
                }
            }
        }
    end
end
event.register(tes3.event.equip, onEquip)