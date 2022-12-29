local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("PaintingActivator")
local Painting = require("mer.joyOfPainting.items.Painting")
---@param e equipEventData
local function onEquip(e)
    local painting = Painting:new{
        item = e.item, ---@type any
        itemData = e.itemData
    }
    if painting:hasPaintingData() then
        painting:paintingMenu()
        return false
    end
end
event.register(tes3.event.equip, onEquip)

---@param painting JOP.Painting
local function showPaintingMenu(painting)
    tes3ui.showMessageMenu{
        message = painting.reference.object.name,
        buttons = {
            {
                text = "View",
                callback = function()
                    painting:paintingMenu()
                end,
            },
            {
                text = "Pick Up",
                callback = function(e)
                    -- Add it to the player's inventory manually.
                    tes3.addItem({
                        reference = tes3.player,
                        item = painting.reference.object, ---@type any
                        count = 1,
                        itemData = painting.reference.itemData,
                    })
                    painting.reference.itemData = nil
                    painting.reference:delete()
                end,
            }
        },
        cancels = true
    }
end

---@param e activateEventData
local function onActivate(e)
    if tes3ui.menuMode() then return end
    if common.isShiftDown() then return end
    if e.activator ~= tes3.player then return end
    local id = e.target.object.id:lower()
    local isFrame = config.frames[id]
    if isFrame then
        logger:debug("Filtering on frame: %s", id)
        return
    end
    if common.isStack(e.target) then
        logger:debug("%s is stack, skip", id)
        return
    end
    local painting = Painting:new{
        reference = e.target,
    }
    if painting:hasPaintingData() then
        showPaintingMenu(painting)
        return false
    end
end
event.register(tes3.event.activate, onActivate)