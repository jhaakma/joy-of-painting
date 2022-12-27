local NodeManager = require("mer.joyOfPainting.services.NodeManager")
local PaintService = require("mer.joyOfPainting.services.PaintService")
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

---@return JoyOfPainting.Painting
function Painting:new(reference)
    local paint = setmetatable({}, Painting)
    paint.id = reference.object.id:lower()
    paint.reference = reference
    -- reference data
    reference.data.joyOfPainting = reference.data.joyOfPainting or {}
    paint.data = reference.data.joyOfPainting
    return paint
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

function Painting:takeCanvas()
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


function Painting.getCanvasObject(dataHolder)
    --get canvas object from id
    if dataHolder.data.joyOfPainting.canvasId then
        return tes3.getObject(dataHolder.data.joyOfPainting.canvasId)
    end
end

function Painting.getPaintingOrCanvasName(dataHolder)
    if not dataHolder then
        logger:debug("no data holder")
        return
    end
    if not dataHolder.data.joyOfPainting then
        return
    end
    if dataHolder.data.joyOfPainting.paintingName then
        logger:debug("painting name: %s", dataHolder.data.joyOfPainting.paintingName)
        return dataHolder.data.joyOfPainting.paintingName
    elseif dataHolder.data.joyOfPainting.canvasId then
        logger:debug("canvas name: %s", Painting.getCanvasObject(dataHolder).name)
        return Painting.getCanvasObject(dataHolder).name
    end
end

return Painting