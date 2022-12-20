local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Easel")
local NodeManager = require("mer.joyOfPainting.services.NodeManager")
local Painting = require("mer.joyOfPainting.items.Painting")
local PhotoMenu = require("mer.joyOfPainting.services.PhotoMenu")
local SkillService = require("mer.joyOfPainting.services.SkillService")
local PaintService = require("mer.joyOfPainting.services.PaintService")

---@class JoyOfPainting.CanvasData
---@field canvasId string|nil The id of the original canvas object
---@field paintingId string|nil The id of the generated painting object
---@field paintingTexture string|nil The path to the painting texture
---@field textureWidth number|nil The width of the painting texture
---@field textureHeight number|nil The height of the painting texture
---@field canvasWidth number|nil The width of the actual canvas
---@field canvasHeight number|nil The height of the actual canvas
---@field artStyle JoyOfPainting.ArtStyle The art style the canvas was painted with

---@class JoyOfPainting.EaselData


-- Easel class
---@class JoyOfPainting.Easel
local Easel = {
    -- name
    ---@type string
    name = nil,

    -- reference
    ---@type tes3reference
    reference = nil,
    -- reference data
    ---@type table
    data = nil,
}
Easel.__index = Easel

local canvasFields = {
    "canvasId",
    "paintingId",
    "paintingTexture",
    "paintingName",
    "location",
    "artStyle",
}

---@return JoyOfPainting.Easel|nil
function Easel:new(reference)
    if not self.isEasel(reference) then return nil end
    local easel = setmetatable({}, self)
    easel.name = reference.object.name or "Easel"
    easel.reference = reference
    -- reference data
    reference.data.joyOfPainting = reference.data.joyOfPainting or {
        canvasId = nil,
        paintingId = nil,
        paintingTexture = nil,
        location = nil,
        artStyle = nil
    }
    ---@type JoyOfPainting.CanvasData
    easel.data = reference.data.joyOfPainting
    return easel
end

function Easel:attachCanvas(item, itemData)
    if item then
        logger:debug("Attaching canvas %s", item.id)
        local isPainting = itemData and itemData.data.joyOfPainting
            and itemData.data.joyOfPainting.paintingTexture
        if isPainting then
            logger:debug("Canvas already has a painting")
            self.data.paintingId = item.id
            self.data.canvasId = itemData.data.joyOfPainting.canvasId
            self.data.paintingTexture = itemData.data.joyOfPainting.paintingTexture
            self.data.location = itemData.data.joyOfPainting.location
            self.data.artSTyle = itemData.data.joyOfPainting.artStyle
            self.data.paintingName = item.name
        else
            logger:debug("Canvas is blank")
            self.data.canvasId = item.id:lower()
        end
        self:doCanvasVisuals()
        local painting = Painting:new(self.reference)
        if painting then
            painting:doPaintingVisuals()
        end
    else
        logger:debug("No canvas selected")
    end
end

function Easel:attachCanvasFromInventory(item, itemData)
    if not tes3.player.object.inventory:contains(item, itemData) then
        logger:debug("Player does not have canvas %s", item.id)
        return
    end
    if item then
        self:attachCanvas(item, itemData)
        --Remove the canvas from the player's inventory
        logger:debug("Removing canvas %s from inventory", item.id)
        tes3.removeItem{
            reference = tes3.player,
            item = item.id,
            itemData = itemData,
            count = 1
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
        Easel.selectCanvasFromInventory(function(e)
            local item = e.item
            local itemData = e.itemData
            timer.delayOneFrame(function()
                self:attachCanvasFromInventory(item, itemData)
            end)
        end)
    end)
end

function Easel:getCanvasData()
    return config.canvases[self.data.canvasId]
end

function Easel:takeCanvas()
    local attachedId = self.data.paintingId or self.data.canvasId
    logger:debug("Taking canvas %s", attachedId)
    tes3.addItem{
        reference = tes3.player,
        item = attachedId,
        count = 1
    }
    local itemData = tes3.addItemData{
        item = attachedId,
        to = tes3.player,
        updateGUI = true,
    }
    if self.data.paintingId then
        itemData.data.joyOfPainting = {
            paintingTexture = self.data.paintingTexture,
            location = self.data.location,
            canvasId = self.data.canvasId,
            paintingId = self.data.paintingId,
            artStyle = self.data.artStyle
        }
    end
    self:resetCanvas()
end

function Easel:resetCanvas()
    for _, field in ipairs(canvasFields) do
        self.data[field] = nil
    end
    --Remove children from the attach_canvas node
    local attachNode = NodeManager.getEaselAttachNode(self.reference.sceneNode)
    if attachNode then
        attachNode:detachChildAt(1)
        attachNode:update()
    end
end



function Easel:cleanCanvas()
    logger:debug("Cleaning canvas")
    local canvasId = self.data.canvasId
    self:resetCanvas()
    self.data.canvasId = canvasId
    local canvas = tes3.getObject(canvasId)
    self:attachCanvas(canvas)
end


function Easel:doPaintAnim()
    logger:debug("doPaintAnim()")

    --get texture node
    local paintTexNode = self.reference.sceneNode:getObjectByName(NodeManager.nodes.PAINT_ANIM_TEX_NODE)
    assert(paintTexNode ~= nil, "No paint node found on easel")

    --set texture
    NodeManager.cloneTextureProperty(paintTexNode)
    ---@type niSourceTexture
    ---@diagnostic disable-next-line: assign-type-mismatch
    paintTexNode.texturingProperty.baseMap.texture = PaintService.createTexture(self.data.paintingTexture)
    paintTexNode:update()
    paintTexNode:updateProperties()

    --reset animation
    self:resetPaintTime()

    timer.delayOneFrame(function()
        --set index to animation node
        local switchNode = self.reference.sceneNode:getObjectByName(NodeManager.nodes.PAINT_SWITCH)
        local animIndex = NodeManager.getIndex(switchNode, NodeManager.nodes.PAINT_SWITCH_ANIMATING )
        switchNode.switchIndex = animIndex
    end)
end

--Creates a new misc item with the paintingTexture as the ID and the path to the icon
function Easel:createPaintingObject(paintingName)
    assert(self.data.paintingTexture ~= nil, "No painting texture set")
    local canvasObj = tes3.getObject(self.data.canvasId)
    local paintingObject = tes3.createObject{
        id = self.data.paintingTexture,
        name = paintingName,
        mesh = canvasObj.mesh,
        enchantment = canvasObj.enchantment,
        weight = canvasObj.weight,
        type = canvasObj.type,
        maxCondition = canvasObj.maxCondition,
        speed = canvasObj.speed,
        reach = canvasObj.reach,
        enchantCapacity = canvasObj.enchantCapacity,
        chopMin = canvasObj.chopMin,
        chopMax = canvasObj.chopMax,
        slashMin = canvasObj.slashMin,
        slashMax = canvasObj.slashMax,
        thrustMin = canvasObj.thrustMin,
        thrustMax = canvasObj.thrustMax,
        materialFlags = canvasObj.flags,
        getIfExists = false,
        objectType = canvasObj.objectType,
        icon = PaintService.getPaintingIconPath(self.data.paintingTexture),
        value = SkillService.getPaintingValue(),
    }
    logger:debug("Created painting object %s", paintingObject.id)
    return paintingObject
end

---Start painting
function Easel:paint(artStyle)
    self.data.artStyle = config.artStyles[artStyle]
    self.reference.sceneNode.appCulled = true
    local canvas = self:getCanvasData()
    if canvas then
        timer.delayOneFrame(function()
            PhotoMenu:new{
                canvas = canvas,
                artStyle = self.data.artStyle,
                captureCallback = function(e)
                    --set paintingTexture before creating object
                    self.data.paintingTexture = e.paintingTexture
                    self.data.location = tes3.player.cell.displayName
                    self:doPaintAnim()
                    self.reference.sceneNode.appCulled = false
                end,
                closeCallback = function()
                    self.reference.sceneNode.appCulled = false
                end,
                cancelCallback = function()
                    logger:debug("Cancelling painting")
                    tes3.messageBox("You scrape the paint from the canvas.")
                    self:cleanCanvas()
                end,
                finalCallback = function(e)
                    logger:debug("Creating new object for painting %s", e.paintingName)
                    local newPaintingObject = self:createPaintingObject(e.paintingName)
                    self.data.paintingId = newPaintingObject.id
                    self.data.paintingName = newPaintingObject.name

                    tes3.messageBox("Successfully created %s", newPaintingObject.name)
                    --assert all canvas fields are filled in
                    for _, field in ipairs(canvasFields) do
                        assert(self.data[field] ~= nil, "Missing field %s", field)
                    end
                    --self:takeCanvas()
                end
            }:open()
        end)
    else
        logger:error("No canvas data found for %s", self.data.canvasId)
        return
    end
end

function Easel:pickUp()
    logger:debug("TODO: Pick up easel")
end

---@return boolean
function Easel:canAttachCanvas()
    return self.data.canvasId == nil
        and Easel.playerHasCanvas()
end

function Easel:getCanvasObject()
    --get canvas object from id
    if self.data.canvasId then
        return tes3.getObject(self.data.canvasId)
    end
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

function Easel:resetPaintTime()
    local now = tes3.getSimulationTimestamp(false)
    local root = self.reference.sceneNode
    for node in table.traverse{root} do
        if node.controller then
            node.controller.phase = -now + config.ANIM_OFFSET
        end
        for _, prop in pairs{node.materialProperty, node.texturingProperty} do
            if prop.controller then
                prop.controller.phase = -now + config.ANIM_OFFSET
            end
        end
    end
end

function Easel:doCanvasVisuals()
    if not self.data.canvasId then return end
    --Attach the canvas mesh to the attach_canvas node
    local easelAttachNode = NodeManager.getEaselAttachNode(self.reference.sceneNode)

    if easelAttachNode then
        local canvasObject = tes3.getObject(self.data.canvasId)
        local mesh = tes3.loadMesh(canvasObject.mesh, false)
        local clonedMesh = mesh:clone() ---@type any
        NodeManager.moveOriginToAttachPoint(clonedMesh)
        easelAttachNode:attachChild(clonedMesh)
        easelAttachNode:update()
        easelAttachNode:updateEffects()
    end
end


function Easel:getPaintingOrCanvasName()
    if self.data.paintingName then
        return self.data.paintingName
    elseif self.data.canvasId then
        return self:getCanvasObject().name
    else
        return "No Canvas Attached"
    end
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
                if variable.data
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

function Easel.isCanvas(e)
    local canvasData = config.canvases[e.item.id:lower()]
    return canvasData ~= nil
end

function Easel.isPainting(e)
    local paintingData = e.itemData
        and e.itemData.data.joyOfPainting
        and e.itemData.data.joyOfPainting.paintingTexture
    return paintingData ~= nil
end

function Easel.isCanvasOrPainting(e)
    return Easel.isCanvas(e) or Easel.isPainting(e)
end

--open an inventorySelectMenu filtered on canvas items
function Easel.selectCanvasFromInventory(callback)
    tes3ui.showInventorySelectMenu{
        title = "Select a canvas",
        noResultsText = "No canvases found",
        filter = Easel.isCanvasOrPainting,
        callback = function(e)
            if e.item then
                callback{
                    item = e.item,
                    itemData = e.itemData,
                    canvasData = config.canvases[e.item.id:lower()]
                }
            end
        end,
        noResultsCallback = function()
            tes3.messageBox("You don't have any canvases in your inventory.")
        end
    }
end



return Easel



