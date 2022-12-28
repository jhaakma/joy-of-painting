local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("interop")

local Interop = {}

---@class JoyOfPainting.Canvas
---@field canvasId string The id of the canvas. Must be unique.
---@field textureWidth number The width of the texture to be used for the canvas.
---@field textureHeight number The height of the texture to be used for the canvas.
---@field frameSize string The size of the frame to use for the canvas. Must be one of "sqaure", "tall", or "wide"
---@field valueModifier number The value modifier for the painting
---@field canvasTexture string The texture to use for the canvas
---@field meshOverride string? An optional mesh override for the canvas
---@field requiresEasel boolean? Whether the canvas requires an easel to be painted on

local function logAssert(condition, message)
    if not condition then
        logger:error(message)
        assert(condition, message)
    end
end


---@param e JoyOfPainting.Canvas
function Interop.registerCanvas(e)
    logAssert(type(e.canvasId) == "string", "id must be a string")
    logAssert(type(e.textureHeight) == "number", "textureHeight must be a number")
    logAssert(type(e.textureHeight) == "number", "textureHeight must be a number")
    logAssert(type(e.frameSize) == "string", "frameSize must be a string")
    logAssert(type(e.valueModifier) == "number", "valueModifier must be a number")
    logAssert(type(e.canvasTexture) == "string", "canvasTexture must be a string")

    logger:debug("Registering canvas %s with frameSize %s", e.canvasId, e.frameSize)
    local id = e.canvasId:lower()
    config.canvases[id] = {
        canvasId = id,
        textureWidth = e.textureWidth,
        textureHeight = e.textureHeight,
        frameSize = e.frameSize,
        valueModifier = e.valueModifier,
        canvasTexture = e.canvasTexture,
        requiresEasel = e.requiresEasel,
    }
    if e.meshOverride then
        local obj = tes3.getObject(id)
        if not obj then
            logger:error("Could not find object %s", id)
            return
        end
        local originalMesh = "meshes\\" .. obj.mesh:lower()
        logger:debug("Registering mesh override for %s: %s -> %s", id, originalMesh, e.meshOverride)
        config.meshOverrides[originalMesh] = e.meshOverride:lower()
    end
end

---@class JoyOfPainting.PaintingEquipment
---@field toolId string The id of the tool to use for painting
---@field paintHolderId string The id of the paint holder to use for painting
---@field consumesPaintHolder boolean Whether the paint holder should be consumed when painting
---@field paintConsumed number The amount of paint consumed when painting

---@class JoyOfPainting.ArtStyle
---@field name string The name of the art style
---@field magickCommand function A function that returns a Magick command to execute
---@field shaders table<string> A list of shaders to apply to the painting
---@field valueModifier number The value modifier for the painting
---@field soundEffect string The sound effect to play when painting
---@field animAlphaTexture string The texture used to control the alpha during painting animation
---@field equipment JoyOfPainting.PaintingEquipment[] A list of painting equipment to use for this art style

---@param e JoyOfPainting.ArtStyle
function Interop.registerArtStyle(e)
    logAssert(type(e.name) == "string", "name must be a string")
    logAssert(type(e.magickCommand) == "function", "magickCommand must be a function")
    logAssert(type(e.shaders) == "table", "shaders must be a table")
    logAssert(type(e.valueModifier) == "number", "valueModifier must be a number")
    logAssert(type(e.soundEffect) == "string", "soundEffect must be a string")
    logger:debug("Registering art style %s", e.name)

    config.artStyles[e.name] = {
        name = e.name,
        magickCommand = e.magickCommand,
        shaders = e.shaders,
        valueModifier = e.valueModifier,
        soundEffect = e.soundEffect,
        animAlphaTexture = e.animAlphaTexture,
        equipment = e.equipment,
    }
end

--[[
    Register a frame size, which allows canvases to have the right frame
]]
function Interop.registerFrameSize(e)
    logAssert(type(e.id) == "string", "id must be a string")
    logAssert(type(e.width) == "number", "width must be a number")
    logAssert(type(e.height) == "number", "aspectRatio.height must be a number")
    logger:debug("Registering frame size %s", e.id)
    local id = e.id:lower()
    config.frameSizes[id] = {
        id = id,
        width = e.width,
        height = e.height,
        aspectRatio = e.width / e.height,
    }
end

function Interop.registerFrame(e)
    logAssert(type(e.id) == "string", "id must be a string")
    logAssert(type(e.frameSize) == "string", "frameSize must be a string")
    logger:debug("Registering frame %s", e.id)
    local id = e.id:lower()
    config.frames[id] = {
        id = id,
        texture = e.texture,
        frameSize = e.frameSize,
    }
end

return Interop

