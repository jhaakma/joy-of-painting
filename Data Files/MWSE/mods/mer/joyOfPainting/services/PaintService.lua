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

function PaintService.getSavedPaintingDimensions(image)
    local aspectRatio = config.frameSizes[image.canvasConfig.frameSize].aspectRatio
    local savedImageSize = config.mcm.savedPaintingSize

    local width
    local height
    if image.canvasConfig.textureWidth > image.canvasConfig.textureHeight then
        width = savedImageSize * aspectRatio
        height = savedImageSize
    else
        width = savedImageSize
        height = savedImageSize / aspectRatio
    end
    return width, height
end

function PaintService.getSavedPaintingPath()
    local currentPaintingIndex = config.mcm.savedPaintingIndex
    return "textures\\jop\\saved\\" .. currentPaintingIndex .. ".png"
end


function PaintService.getPaintingIconPath(texture)
    return "jop\\p\\" .. texture
end

function PaintService.getSketchTexture()
    return config.locations.sketchTexture
end

function PaintService.getPaintingDimensions(canvasId, maxHeight)
    logger:debug("Getting painting dimensions for %s. Max height: %s",
        canvasId, maxHeight)
    local canvasData = config.canvases[canvasId]
    local textureHeight = math.min(canvasData.textureHeight, maxHeight)

    local frameSize = config.frameSizes[canvasData.frameSize]
    if not frameSize then
        logger:error("Frame Size '%s' is not registered.", canvasData.frameSize)
        return
    end
    local ratio = frameSize.aspectRatio

    local height = textureHeight
    local width = textureHeight * ratio
    return {
        width = width,
        height = height
    }
end

return PaintService