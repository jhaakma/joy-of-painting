local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("PaintService")

local PaintService = {}

function PaintService.createTexture(texture)
    return niSourceTexture.createFromPath(PaintService.getPaintingTexturePath(texture), false)
end

function PaintService.createIcon(texture)
    local path = "Icons\\" .. PaintService.getPaintingIconPath(texture)
    logger:debug("Creating icon from path %s", path)
    return niSourceTexture.createFromPath(path, true)
end

function PaintService.getPaintingTexturePath(texture)
    return "textures\\jop\\p\\" .. texture
end

function PaintService.getPaintingIconPath(texture)
    return "jop\\p\\" .. texture
end

function PaintService.getSketchTexture()
    return config.locations.sketchTexture
end

function PaintService.hasPaintingData(dataHolder)
    return dataHolder
        and dataHolder.data
        and dataHolder.data.joyOfPainting
        and dataHolder.data.joyOfPainting.paintingTexture
end

function PaintService.hasFrameData(dataHolder)
    return dataHolder
    and dataHolder.data
    and dataHolder.data.joyOfPainting
    and dataHolder.data.joyOfPainting.frameId
end


function PaintService.getPaintingDimensions(canvasId, maxHeight)
    logger:debug("Getting painting dimensions for %s. Max height: %s",
        canvasId, maxHeight)
    local dimensions = config.canvases[canvasId]
    local textureHeight = math.min(dimensions.textureHeight, maxHeight)
    local canvasWidth = dimensions.canvasWidth
    local canvasHeight = dimensions.canvasHeight
    local ratio = canvasWidth / canvasHeight

    local height = textureHeight
    local width = textureHeight * ratio
    return {
        width = width,
        height = height
    }
end

return PaintService