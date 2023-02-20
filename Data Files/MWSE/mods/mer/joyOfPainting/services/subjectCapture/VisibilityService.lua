local VisibilityService = {}

local cullingPlanes = {}

local prevTime = 0
local function updateCullingPlanes()
    local camera = tes3.worldController.worldCamera.cameraData.camera
    local currTime = tes3.getSimulationTimestamp(false)

    -- time-based caching, enables being used by multiple
    -- callers in the same frame without doing extra work
    if not math.isclose(currTime, prevTime) then
        for i, plane in pairs(camera.cullingPlanes) do
            local normal = tes3vector3.new(plane.x, plane.y, plane.z)
            local distance = normal:dot(camera.translation) - plane.w
            cullingPlanes[i] = { normal = normal, distance = distance, constant = plane.w }
        end
    end

    prevTime = currTime
end

---@return boolean
function VisibilityService.isSphereVisible(origin, radius)
    updateCullingPlanes()

    for _, plane in ipairs(cullingPlanes) do
        local distance = plane.normal:dot(origin) + plane.distance
        if distance < -radius then
            return false
        end
    end

    return true
end

---@return boolean
function VisibilityService.isBoxVisible(box)
    updateCullingPlanes()

    local vertices = box:vertices()

    for _, plane in ipairs(cullingPlanes) do
        local count = 8

        for _, vertex in ipairs(vertices) do
            local distance = plane.normal:dot(vertex) - plane.constant
            if distance < 0 then
                count = count - 1
            end
        end

        if count == 0 then
            return false
        end
    end

    return true
end

return VisibilityService