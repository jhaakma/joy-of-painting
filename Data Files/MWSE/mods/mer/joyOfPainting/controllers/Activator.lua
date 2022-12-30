local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Activator")
local Painting = require("mer.joyOfPainting.items.Painting")
local PaperActivator = require("mer.joyOfPainting.activators.PaperActivator")
local PaintingActivator = require("mer.joyOfPainting.activators.PaintingActivator")
local FrameActivator = require("mer.joyOfPainting.activators.FrameActivator")
local SketchbookActivator = require("mer.joyOfPainting.activators.SketchbookActivator")

---@param e activateEventData
local function doBlockActivate(e)
    if tes3ui.menuMode() then
        logger:debug("Menu mode, skip")
        return true
    end
    if common.isShiftDown() then return true end
    if e.activator ~= tes3.player then
        logger:debug("Not player, skip")
        return true
    end
    if common.isStack(e.target) then
        logger:debug("%s is stack, skip", e.target.object.id)
        return true
    end
    return false
end


---@param e activateEventData
local function getActivatorType(e)
    --sketchbook
    if config.sketchbooks[e.target.object.id:lower()] then
        return SketchbookActivator
    end
    --frame
    if config.frames[e.target.object.id:lower()] then
        return FrameActivator
    end
    --painting
    local painting = Painting:new{reference = e.target}
    if painting:hasPaintingData() then
        return PaintingActivator
    end
    --paper
    local canvasConfig = painting:getCanvasConfig()
    if canvasConfig and not canvasConfig.requiresEasel then
        return PaperActivator
    end
end

---@param e activateEventData
local function onActivate(e)
    if doBlockActivate(e) then return end
    local activatorType = getActivatorType(e)
    if activatorType then
        logger:debug("Activator type: %s", activatorType)
        activatorType.activate(e)
        return false
    end
end
event.register("activate", onActivate)

---@param e equipEventData
local function onEquip(e)
    local painting = Painting:new{
        item = e.item, ---@type any
        itemData = e.itemData
    }
    if painting:hasPaintingData() then
        PaintingActivator.activate(e)
    end

    if config.sketchbooks[e.item.id:lower()] then
        SketchbookActivator.activate(e)
    end
end
event.register("equip", onEquip)