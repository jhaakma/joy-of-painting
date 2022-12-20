local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("interop")

local Interop = {}

---@class JoyOfPainting.Canvas
---@field canvasId string The id of the canvas. Must be unique.
---@field textureWidth number The width of the texture to be used for the canvas.
---@field textureHeight number The height of the texture to be used for the canvas.
---@field canvasWidth number The width of the canvas in pixels.
---@field canvasHeight number The height of the canvas in pixels.
---@field valueModifier number The value modifier for the painting
---@field canvasTexture string The texture to use for the canvas


---@param e JoyOfPainting.Canvas
function Interop.registerCanvas(e)
    assert(type(e.canvasId) == "string", "id must be a string")
    assert(type(e.textureHeight) == "number", "textureHeight must be a number")
    assert(type(e.textureHeight) == "number", "textureHeight must be a number")
    assert(type(e.canvasWidth) == "number", "canvasWidth must be a number")
    assert(type(e.canvasHeight) == "number", "canvasHeight must be a number")
    assert(type(e.valueModifier) == "number", "valueModifier must be a number")
    assert(type(e.canvasTexture) == "string", "canvasTexture must be a string")
    logger:debug("Registering canvas %s with dimensions %s x %s", e.id, e.canvasWidth, e.canvasHeight)
    local id = e.canvasId:lower()
    config.canvases[id] = {
        canvasId = id,
        textureWidth = e.textureWidth,
        textureHeight = e.textureHeight,
        canvasWidth = e.canvasWidth,
        canvasHeight = e.canvasHeight,
        valueModifier = e.valueModifier,
        canvasTexture = e.canvasTexture,
    }
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
    assert(type(e.name) == "string", "name must be a string")
    assert(type(e.magickCommand) == "function", "magickCommand must be a function")
    assert(type(e.shaders) == "table", "shaders must be a table")
    assert(type(e.valueModifier) == "number", "valueModifier must be a number")
    assert(type(e.soundEffect) == "string", "soundEffect must be a string")
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

return Interop

