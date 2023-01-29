local pixelCounter = require("mer.joyOfPainting.services.pixelCounter")

---@class OcclusionTester
---@field targets niNode[]
---@field root niNode
---@field mask niNode
---@field camera niCamera
---@field texture niRenderedTexture
---@field pixelData niPixelData
local OcclusionTester = {}
OcclusionTester.__index = OcclusionTester

---@class OcclusionTester.params
---@field resolutionScale number

function OcclusionTester.getNearestPowerOfTwo(n)
    return 2 ^ math.floor(math.log(n, 2))
end

--- Create a new occlusion tester. Must be called *after* `initalized`.
---
---@param e OcclusionTester.params|nil
---@return OcclusionTester
function OcclusionTester.new(e)
    e = e or {}
    local this = setmetatable({}, OcclusionTester)

    -- Rounds width and height to nearest power of two.
    local s = e.resolutionScale or 1.0
    local w, h = tes3ui.getViewportSize()
    w = OcclusionTester.getNearestPowerOfTwo(w * s)
    h = OcclusionTester.getNearestPowerOfTwo(h * s)
    assert(w >= 128 and h >= 128)

    -- Create the render target texture and pixel data.
    this.texture = assert(niRenderedTexture.create(w, h))
    this.pixelData = niPixelData.new(w, h)

    -- Create the utility meshes for managing stencils.
    ---@diagnostic disable
    this.root = assert(tes3.loadMesh("jop\\occlusionTester.nif")):clone()
    this.mask = assert(this.root:getObjectByName("Masked Objects"))
    ---@diagnostic enable

    -- Attach to camera, assign a convenience accessor.
    this.camera = tes3.worldController.worldCamera.cameraData.camera
    this.camera.parent:attachChild(this.root)

    -- Array of sceneNodes that we are testing against.
    this.targets = {}

    return this
end

--- Set the target scene objects that will be occlusion tested.
---
---@param sceneNodes niNode[]
function OcclusionTester:setTargets(sceneNodes)
    -- clear previous targets
    self.targets = {}
    self.mask:detachAllChildren()

    -- collect the new targets
    for _, node in pairs(sceneNodes) do
        table.insert(self.targets, node)
        for shape in table.traverse({ node }) do
            if shape:isInstanceOfType(tes3.niType.NiTriShape)
                and not shape:isAppCulled()
            then
                local t = shape.worldTransform
                shape = shape:clone()
                shape:copyTransforms(t)
                shape:detachAllProperties()
                self.mask:attachChild(shape, true)
            end
        end
    end

    self.mask:clearTransforms()
    self.mask:update()
end

--- Returns a normalized value representing the ratio of pixels that are not occluded.
---
---@return number
function OcclusionTester:getVisibility()
    local ratio = 0.0

    local maximum = self:getPixelCounts({ visibleOnly = false })
    if maximum ~= 0 then
        local visible = self:getPixelCounts({ visibleOnly = true })
        ratio = (visible / maximum)
    end
    return ratio
end

--- Returns a normalized value representing the ratio of active, visible
--- pixels compared to the total pixels in the scene.
function OcclusionTester:getPresence()
    local ratio = 0.0

    local active, total = self:getPixelCounts({ visibleOnly = true })
    if total ~= 0 then
        ratio = (active / total)
    end
    return ratio
end

function OcclusionTester:getActiveEdgePixelRatio()
    local ratio = 0.0

    local active, total = self:getPixelCounts({ visibleOnly = true, edgeOnly = true })
    if total ~= 0 then
        ratio = (active / total)
    end
    return ratio
end

function OcclusionTester:enable()
    self.root.appCulled = false
    self.root:update()
    for _, node in ipairs(self.targets) do
        node.appCulled = true
    end
end

function OcclusionTester:disable()
    self.root.appCulled = true
    self.root:update()
    for _, node in ipairs(self.targets) do
        node.appCulled = false
    end
end

function OcclusionTester:capturePixelData()
    ---@diagnostic disable
    self.camera.renderer:setRenderTarget(self.texture)
    self.camera:clear()
    self.camera:click()
    self.camera:swapBuffers()
    self.camera.renderer:setRenderTarget(nil)
    ---@diagnostic enable
    assert(self.texture:readback(self.pixelData))
end

function OcclusionTester:getPixelCounts(e)
    e = e or { visibleOnly = false, edges = false }
    if e.visibleOnly then
        self.mask.zBufferProperty.testFunction = ni.zBufferPropertyTestFunction.lessEqual
    else
        self.mask.zBufferProperty.testFunction = ni.zBufferPropertyTestFunction.always
    end
    self:capturePixelData()
    if e.edges then
        return pixelCounter.countActiveEdgePixels(self.pixelData)
    else
        return pixelCounter.countActivePixels(self.pixelData)
    end
end


return OcclusionTester
