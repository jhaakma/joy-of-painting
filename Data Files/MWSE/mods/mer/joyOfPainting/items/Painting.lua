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

---@return JoyOfPainting.Painting|nil
function Painting:new(reference)
    if not PaintService.hasPaintingData(reference) then
        return nil
    end
    logger:debug("%s has paint", reference.object.id)
    local paint = setmetatable({}, Painting)
    paint.id = reference.object.id:lower()
    paint.reference = reference
    -- reference data
    reference.data.joyOfPainting = reference.data.joyOfPainting or {}
    paint.data = reference.data.joyOfPainting
    return paint
end

function Painting:doPaintingVisuals()
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

return Painting