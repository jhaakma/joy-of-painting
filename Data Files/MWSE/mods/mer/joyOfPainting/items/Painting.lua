local NodeManager = require("mer.joyOfPainting.services.NodeManager")
local PaintService = require("mer.joyOfPainting.services.PaintService")
local SkillService = require("mer.joyOfPainting.services.SkillService")
local PhotoMenu = require("mer.joyOfPainting.services.PhotoMenu")
local UIHelper = require("mer.joyOfPainting.services.UIHelper")
local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Painting")
--[[
    Painting class for managing any item that has a painting
]]

---@class JoyOfPainting.Painting
local Painting = {
    -- id
    ---@type string
    id = nil,
    -- reference
    ---@type tes3reference
    reference = nil,
    -- reference data
    ---@type table
    data = nil,
}

Painting.__index = Painting

Painting.canvasFields = {
    "canvasId",
    "paintingId",
    "paintingTexture",
    "paintingName",
    "location",
    "artStyle",
}


function Painting.hasCanvasData(dataHolder)
    return (dataHolder
        and dataHolder.data
        and dataHolder.data.joyOfPainting
        and dataHolder.data.joyOfPainting.canvasId) ~= nil
end

function Painting.getCanvasId(dataHolder)
    if Painting.hasCanvasData(dataHolder) then
        return dataHolder.data.joyOfPainting.canvasId
    end
end

function Painting.hasPaintingData(dataHolder)
    return (dataHolder
        and dataHolder.data
        and dataHolder.data.joyOfPainting
        and dataHolder.data.joyOfPainting.paintingTexture) ~= nil
end

function Painting.getCanvasObject(dataHolder)
    --get canvas object from id
    if dataHolder.data.joyOfPainting.canvasId then
        return tes3.getObject(dataHolder.data.joyOfPainting.canvasId)
    end
end

function Painting.getCanvasData(item, dataHolder)
    local canvasId = Painting.getCanvasId(dataHolder)
        or item.id:lower()
    ---@type JoyOfPainting.Canvas
    local canvasConfig = config.canvases[canvasId]
    return canvasConfig
end

function Painting.getPaintingOrCanvasName(dataHolder)
    local paintingData = dataHolder
        and dataHolder.data
        and dataHolder.data.joyOfPainting
    if not paintingData then return end
    if paintingData.paintingName then
        return paintingData.paintingName
    elseif paintingData.canvasId then
        return Painting.getCanvasObject(dataHolder).name
    end
end

function Painting.clearCanvas(item, dataHolder)
    logger:debug("Clearing painting data")
    if config.frames[item.id:lower()] then
        dataHolder.data.joyOfPainting.paintingTexture = nil
        dataHolder.data.joyOfPainting.paintingName = nil
        dataHolder.data.joyOfPainting.paintingId = nil

        if dataHolder.object then Painting:new(dataHolder):doVisuals() end
    else
        tes3.addItem{
            item = dataHolder.data.joyOfPainting.canvasId,
            count = 1,
            reference = tes3.player,
            playSound = false,
        }
        tes3.removeItem{
            item = item.id,
            itemData = dataHolder,
            count = 1,
            reference = tes3.player,
            playSound = false,
        }
    end
end

function Painting.paintingMenu(item, dataHolder)
    local isPainting = Painting.hasPaintingData(dataHolder)
    if isPainting then
        logger:debug("Canvas Activated")
        local paintingData = dataHolder.data.joyOfPainting
        local paintingTexture = paintingData.paintingTexture
        local tooltipText = string.format("Location: %s.", paintingData.location)
        local paintingName = paintingData.paintingName or item.name
        local tooltipHeader = paintingName
        logger:debug("Painting Name: %s", paintingName)
        UIHelper.openPaintingMenu{
            canvasId = paintingData.canvasId,
            paintingTexture = paintingTexture,
            tooltipHeader = tooltipHeader,
            tooltipText = tooltipText,
            dataHolder = paintingData,
            callback = function()
                tes3.messageBox("Renamed to '%s'", paintingData.paintingName)
                if not config.frames[item.id:lower()] then
                    item.name = paintingData.paintingName
                end
            end,
            buttons = {
                {
                    text = "Scrape",
                    callback = function()
                        UIHelper.scrapePaintingMessage(function()
                            Painting.clearCanvas(item, dataHolder)
                        end)
                    end,
                    closesMenu = true
                },
            }
        }
    end
end


---@return JoyOfPainting.Painting
function Painting:new(reference)
    local painting = setmetatable({}, Painting)
    painting.id = reference.object.id:lower()
    painting.reference = reference
    -- reference data
    reference.data.joyOfPainting = reference.data.joyOfPainting or {}
    painting.data = reference.data.joyOfPainting
    return painting
end

function Painting:doVisuals()
    self:doCanvasVisuals()
    self:doPaintingVisuals()
end

function Painting:doCanvasVisuals()
    if not self.data.canvasId then return end
    logger:debug("doCanvasVisuals for %s", self.id)
    --Attach the canvas mesh to the attach_canvas node
    local attachNode = NodeManager.getCanvasAttachNode(self.reference.sceneNode)
    if attachNode then
        if attachNode.children and #attachNode.children > 0 then
            for i = 1, #attachNode.children do
                attachNode:detachChildAt(i)
            end
        end
        local canvasObject = tes3.getObject(self.data.canvasId)
        local mesh = tes3.loadMesh(canvasObject.mesh, false)
        local clonedMesh = mesh:clone() ---@type any
        NodeManager.moveOriginToAttachPoint(clonedMesh)
        attachNode:attachChild(clonedMesh)
        attachNode:update()
        attachNode:updateEffects()
    end
end


function Painting:resetPaintTime()
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

function Painting:doPaintAnim()
    logger:debug("doPaintAnim()")

    --get texture node
    local paintTexNode = self.reference.sceneNode:getObjectByName(NodeManager.nodes.PAINT_ANIM_TEX_NODE)
    assert(paintTexNode ~= nil, "No paint node found")

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
function Painting:createPaintingObject(paintingName)
    assert(self.data.paintingTexture ~= nil, "No painting texture set")

    local canvasObj = tes3.getObject(self.data.canvasId or self.reference.object.id:lower())
    logger:debug("EnchantCapacity = %s", canvasObj.enchantCapacity)
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
        objectType = tes3.objectType.miscItem,--canvasObj.objectType,
        icon = PaintService.getPaintingIconPath(self.data.paintingTexture),
        value = SkillService.getPaintingValue(),
    }
    logger:debug("Created painting object %s", paintingObject.id)
    return paintingObject
end



function Painting:doPaintingVisuals()
    if not self.data.paintingTexture then return end
    logger:debug("doPaintingVisuals for %s", self.id)
    local paintingTexture = PaintService.createTexture(self.data.paintingTexture)
    local switchPaintNode = self.reference.sceneNode:getObjectByName(NodeManager.nodes.PAINT_SWITCH)
    local paintTextureNode = self.reference.sceneNode:getObjectByName(NodeManager.nodes.PAINT_TEX_NODE)
    -- check if the ref has a painting (reference.data.joyOfPainting.paintingTexture)
    if paintingTexture and switchPaintNode and paintTextureNode then
        logger:debug("Painting texture found for %s", self.id)
        -- set switch to paintNode
        local paintedNodeIndex = NodeManager.getIndex(switchPaintNode, NodeManager.nodes.PAINT_SWITCH_PAINTED)
        switchPaintNode.switchIndex = paintedNodeIndex
        --set texture
        NodeManager.cloneTextureProperty(paintTextureNode)
        paintTextureNode.texturingProperty.baseMap.texture = paintingTexture
        paintTextureNode:update()
        paintTextureNode:updateProperties()
    end
end

function Painting:resetCanvas()
    for _, field in ipairs(Painting.canvasFields) do
        self.data[field] = nil
    end
    --Remove children from the attach_canvas node
    local attachNode = NodeManager.getCanvasAttachNode(self.reference.sceneNode)
    if attachNode then
        attachNode:detachChildAt(1)
        attachNode:update()
    end
end

function Painting:attachCanvas(item, itemData)
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
            self.data.artStyle = itemData.data.joyOfPainting.artStyle
            self.data.paintingName = itemData.data.joyOfPainting.paintingName or item.name
        else
            logger:debug("Canvas is blank")
            self.data.canvasId = item.id:lower()
        end
        if Painting.hasCanvasData(self.reference) then
            self:doVisuals()
        end
    else
        logger:debug("No canvas selected")
    end
end

function Painting:cleanCanvas()
    logger:debug("Cleaning canvas")
    local canvasId = self.data.canvasId or self.reference.object.id
    self:resetCanvas()
    self.data.canvasId = canvasId
    local canvas = tes3.getObject(canvasId)
    self:attachCanvas(canvas)
end


function Painting:takeCanvas()
    local attachedId = self.data.paintingId or self.data.canvasId
        or self.reference.object.id
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




return Painting