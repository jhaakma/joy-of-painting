local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Easel")
local NodeManager = require("mer.joyOfPainting.services.NodeManager")
local Painting = require("mer.joyOfPainting.items.Painting")
local PhotoMenu = require("mer.joyOfPainting.services.PhotoMenu")
local SkillService = require("mer.joyOfPainting.services.SkillService")
local PaintService = require("mer.joyOfPainting.services.PaintService")

---@class JOP.CanvasData
---@field canvasId string|nil The id of the original canvas object
---@field paintingId string|nil The id of the generated painting object
---@field paintingTexture string|nil The path to the painting texture
---@field textureWidth number|nil The width of the painting texture
---@field textureHeight number|nil The height of the painting texture
---@field artStyle JOP.ArtStyle The art style the canvas was painted with

-- Easel class
---@class JOP.Easel
local Easel = {
    classname = "Easel",
    ---@type string
    name = nil,
    ---@type tes3reference
    reference = nil,
    ---@type table
    data = nil,
    ---@type JOP.Painting
    painting = nil
}
Easel.__index = Easel

---@param reference tes3reference
---@return JOP.Easel|nil
function Easel:new(reference)
    if not self.isEasel(reference) then return nil end
    local easel = setmetatable({}, self)
    easel.name = reference.object.name or "Easel"
    easel.reference = reference
    easel.data = setmetatable({}, {
        __index = function(t, k)
            if not easel.reference.data.joyOfPainting then
                return nil
            end
            return easel.reference.data.joyOfPainting[k]
        end,
        __newindex = function(t, k, v)
            if not easel.reference.data.joyOfPainting then
                easel.reference.data.joyOfPainting = {}
            end
            easel.reference.data.joyOfPainting[k] = v
        end
    })
    easel.painting = Painting:new{ reference = easel.reference }
    return easel
end


function Easel:attachCanvasFromInventory(item, itemData)
    if not tes3.player.object.inventory:contains(item, itemData) then
        logger:debug("Player does not have canvas %s", item.id)
        return
    end
    if item then
        self.painting:attachCanvas(item, itemData)
        --Remove the canvas from the player's inventory
        logger:debug("Removing canvas %s from inventory", item.id)
        tes3.removeItem{
            reference = tes3.player,
            item = item.id,
            itemData = itemData,
            count = 1,
            playSound = false,
        }
    else
        logger:debug("No canvas selected")
    end
end

--[[
    Opens the inventory select menu to select a canvas to attach to the easel
]]
function Easel:openAttachCanvasMenu()
    timer.delayOneFrame(function()
        tes3ui.showInventorySelectMenu{
            title = "Select a canvas",
            noResultsText = "No canvases found",
            callback = function(e)
                timer.delayOneFrame(function()
                    if e.item then
                        self:attachCanvasFromInventory(e.item, e.itemData)
                    end
                end)
            end,
            filter = function(e2)
                local painting = Painting:new{ item = e2.item, itemData = e2.itemData }
                local canvasId = (painting.data.canvasId or e2.item.id):lower()
                local canvasConfig = config.canvases[canvasId]
                local isFrame = config.frames[e2.item.id]
                if isFrame then
                    logger:trace("Filtering on frame: %s", e2.item.id)
                    return false
                end
                if not canvasConfig then
                    logger:trace("Filtering on canvas %s: no config", e2.item.id)
                    return false
                end
                if not canvasConfig.requiresEasel then
                    logger:trace("Filtering on canvas %s: does not require easel", e2.item.id)
                    return false
                end
                logger:trace("Filtering on canvas %s", e2.item.id)
                return true
            end,
            noResultsCallback = function()
                tes3.messageBox("You don't have any canvases in your inventory.")
            end
        }
    end)
end

---Start painting
function Easel:paint(artStyle)
    self.data.artStyle = artStyle
    self.reference.sceneNode.appCulled = true
    local canvasConfig = config.canvases[self.data.canvasId]
    assert(canvasConfig, "No canvas config found for canvas " .. self.data.canvasId)
    if canvasConfig then
        timer.delayOneFrame(function()
            PhotoMenu:new{
                canvasConfig = canvasConfig,
                artStyle = config.artStyles[artStyle],
                captureCallback = function(e)
                    --set paintingTexture before creating object
                    self.data.paintingTexture = e.paintingTexture
                    self.data.location = tes3.player.cell.displayName
                    self.painting:doPaintAnim()
                    self.reference.sceneNode.appCulled = false
                end,
                closeCallback = function()
                    self.reference.sceneNode.appCulled = false
                end,
                cancelCallback = function()
                    logger:debug("Cancelling painting")
                    tes3.messageBox("You scrape the paint from the canvas.")
                    self.painting:cleanCanvas()
                end,
                finalCallback = function(e)
                    logger:debug("Creating new object for painting %s", e.paintingName)
                    local newPaintingObject = self.painting:createPaintingObject()
                    self.data.paintingId = newPaintingObject.id
                    self.data.canvasId = self.data.canvasId
                    self.data.paintingName = e.paintingName
                    self.painting:doVisuals()
                    tes3.messageBox("Successfully created %s", newPaintingObject.name)
                    --assert all canvas fields are filled in
                    for _, field in ipairs(Painting.canvasFields) do
                        assert(self.data[field] ~= nil, string.format("Missing field %s", field))
                    end
                end
            }:open()
        end)
    else
        logger:error("No canvas data found for %s", self.data.canvasId)
        return
    end
end

function Easel:rotateCanvas()
    local rotatedId = self.painting:getRotatedId()
    if not rotatedId then
        logger:warn("No rotated canvas found for easel %s with canvas %s",
            self.reference.id, self.data.canvasId)
    end
    self.data.canvasId = rotatedId
    self.painting:doVisuals()
    tes3.playSound{
        reference = self.reference,
        sound = "Item Misc Up",
    }
end

function Easel:pickUp()
    logger:debug("TODO: Pick up easel")
end

---@return boolean
function Easel:canAttachCanvas()
    return self.data.canvasId == nil
        and Easel.playerHasCanvas()
end


---@return boolean
function Easel:hasCanvas()
    return self.data.canvasId ~= nil
end

function Easel:hasPainting()
    return self.data.paintingId ~= nil
end

---@return boolean
function Easel:canPickUp()
    return self.data.carryableId ~= nil
        and not self:hasCanvas()
end




----------------------------------------
-- Static Functions --------------------
----------------------------------------

function Easel.isEasel(reference)
    return reference
        and reference.sceneNode
        and reference.sceneNode:getObjectByName("ATTACH_CANVAS")
end

---Check the player's inventory for canvas items
---@return boolean
function Easel.playerHasCanvas()
    ---@param stack tes3itemStack
    for _, stack in pairs(tes3.player.object.inventory) do
        if config.canvases[stack.object.id:lower()] then
            return true
        end
        if stack.variables then
            for _, variable in ipairs(stack.variables) do
                if variable
                    and variable.data
                    and variable.data.joyOfPainting
                    and variable.data.joyOfPainting.paintingTexture
                then
                    return true
                end
            end
        end
    end
    return false
end

return Easel