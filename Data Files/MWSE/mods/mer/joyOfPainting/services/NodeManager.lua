--[[
    Enums for node names
]]
local NodeManager = {}

NodeManager.nodes = {
    --Canvas nodes
    PAINT_SWITCH = "SWITCH_PAINT",
        PAINT_SWITCH_OFF = "OFF",
        PAINT_SWITCH_ANIMATING = "ANIMATING",
        PAINT_SWITCH_PAINTED = "PAINTED",

    PAINT_ANIM_TEX_NODE = "CANVAS_PAINT_ANIM",
    PAINT_ANIM_UNDER = "CANVAS_PAINT_ANIM_UNDER",
    PAINT_TEX_NODE = "CANVAS_PAINT",
    --Easel nodes
    ATTACH_CANVAS = "ATTACH_CANVAS",

    --Frame
    ATTACH_FRAME = "ATTACH_FRAME",
}

function NodeManager.getIndex(node, name)
	for i, child in ipairs(node.children) do
        local isMatch = name and child and child.name
            and child.name:lower() == name:lower()
		if isMatch then
			return i - 1
		end
	end
end

function NodeManager.cloneTextureProperty(node)
    local prop = node:detachProperty(ni.propertyType.texturing)
    assert(prop ~= nil, "No material property found on node")
    local clonedProp = prop:clone() ---@type any
    node:attachProperty(clonedProp)
end


function NodeManager.getCanvasAttachNode(sceneNode)
    return sceneNode:getObjectByName(NodeManager.nodes.ATTACH_CANVAS)
end

---@param node niNode
function NodeManager.moveOriginToAttachPoint(node)
    local attachPoint = node:getObjectByName("ATTACH_POINT")
    if attachPoint then
        node.rotation = attachPoint.rotation:copy()
        node.translation.x = node.translation.x - attachPoint.translation.x
        node.translation.y = node.translation.y - attachPoint.translation.y
        node.translation.z = node.translation.z - attachPoint.translation.z
        node.scale = node.scale * attachPoint.scale
    end
end

return NodeManager