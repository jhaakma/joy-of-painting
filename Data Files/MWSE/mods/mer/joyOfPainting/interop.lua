local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("interop")

local Interop = {}

local function logAssert(condition, message)
    if not condition then
        logger:error(message)
        assert(condition, message)
    end
end

---@class JOP.Canvas
---@field canvasId string The id of the canvas. Must be unique.
---@field rotatedId string? The id of the canvas to use when rotated. If not provided, the canvas will not be rotatable.
---@field textureWidth number The width of the texture to be used for the canvas.
---@field textureHeight number The height of the texture to be used for the canvas.
---@field frameSize string The size of the frame to use for the canvas. Must be one of "sqaure", "tall", or "wide"
---@field valueModifier number The value modifier for the painting
---@field canvasTexture string The texture to use for the canvas
---@field meshOverride string? An optional mesh override for the canvas
---@field requiresEasel boolean? Whether the canvas requires an easel to be painted on
---@field animSpeed number The speed of the painting animation
---@field animSound string The sound to play while painting

---@param e JOP.Canvas
function Interop.registerCanvas(e)
    logAssert(type(e.canvasId) == "string", "id must be a string")
    logAssert(type(e.textureHeight) == "number", "textureHeight must be a number")
    logAssert(type(e.textureHeight) == "number", "textureHeight must be a number")
    logAssert(type(e.frameSize) == "string", "frameSize must be a string")
    logAssert(type(e.valueModifier) == "number", "valueModifier must be a number")
    logAssert(type(e.canvasTexture) == "string", "canvasTexture must be a string")
    logAssert(type(e.animSpeed) == "number", "animSpeed must be a number")
    logAssert(type(e.animSound) == "string", "animSound must be a string")

    logger:debug("Registering canvas %s with frameSize %s", e.canvasId, e.frameSize)
    local id = e.canvasId:lower()
    config.canvases[id] = table.copy(e, {})
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

---@class JOP.ArtStyle.data
---@field name string The name of the art style
---@field magickCommand function A function that returns a Magick command to execute
---@field shaders string[] A list of shaders to apply to the painting
---@field controls string[] A list of controls to use for this art style
---@field valueModifier number The value modifier for the painting
---@field animAlphaTexture string The texture used to control the alpha during painting animation
---@field paintType string The type of paint to use for this art style
---@field requiresEasel boolean? Whether the art style requires an easel to be painted on

local ArtStyle = require("mer.joyOfPainting.items.ArtStyle")
---@param e JOP.ArtStyle.data
function Interop.registerArtStyle(e)
    logAssert(type(e.name) == "string", "name must be a string")
    logAssert(type(e.magickCommand) == "function", "magickCommand must be a function")
    logAssert(type(e.shaders) == "table", "shaders must be a table")
    logAssert(type(e.valueModifier) == "number", "valueModifier must be a number")
    logger:debug("Registering art style %s", e.name)
    config.artStyles[e.name] = e
end

---@class JOP.ArtStyle.control
---@field id string The id of the control
---@field uniform string the name of the external variable in the shader being manipulated
---@field shader string The shader to use for this control
---@field name string The name of the control (shown in menu)
---@field sliderDefault number The default value for the slider
---@field shaderMin number The minimum value for the shader variable
---@field shaderMax number The maximum value for the shader variable

---@param e JOP.ArtStyle.control
function Interop.registerControl(e)
    logAssert(type(e.id) == "string", "id must be a string")
    logAssert(type(e.shader) == "string", "shader must be a string")
    logAssert(type(e.name) == "string", "name must be a string")
    logAssert(type(e.sliderDefault) == "number", "sliderDefault must be a number")
    logAssert(type(e.shaderMin) == "number", "shaderMin must be a number")
    logAssert(type(e.shaderMax) == "number", "shaderMax must be a number")
    logger:debug("Registering control %s", e.id)
    config.controls[e.id] = table.copy(e, {})
end

--[[
    Register a frame size, which allows canvases to have the right frame
]]
function Interop.registerFrameSize(e)
    logAssert(type(e.id) == "string", "id must be a string")
    logAssert(type(e.width) == "number", "width must be a number")
    logAssert(type(e.height) == "number", "aspectRatio.height must be a number")
    logger:debug("Registering frame size %s", e.id)
    e.id = e.id:lower()
    config.frameSizes[e.id] = table.copy(e, {
        aspectRatio = e.width / e.height,
    })
    assert(math.isclose(config.frameSizes[e.id].aspectRatio, e.width / e.height) )
end

function Interop.registerFrame(e)
    logAssert(type(e.id) == "string", "id must be a string")
    logAssert(type(e.frameSize) == "string", "frameSize must be a string")
    logger:debug("Registering frame %s", e.id)
    e.id = e.id:lower()
    config.frames[e.id] = table.copy(e, {})
end


function Interop.registerSketchbook(e)
    e.id = e.id:lower()
    config.sketchbooks[e.id] = table.copy(e, {})
end


---@class JOP.PaintType
---@field id string The id of the paint type
---@field name string The name of the paint type
---@field brushType string? The brush type to use for this paint type. If not specified, this paint does not need a brush to use.

---@param e JOP.PaintType
function Interop.registerPaintType(e)
    logAssert(type(e.id) == "string", "id must be a string")
    logger:debug("Registering paint type %s", e.id)
    e.id = e.id:lower()
    config.paintTypes[e.id] = table.copy(e, {})
end

---@class JOP.Paint.PaintData
---@field breaks boolean Whether the paint breaks when uses run out
---@field uses number The number of uses for the paint
---@field paintTypes table<string, boolean> A list of paint types that this paint can be used withq

---@param e JOP.Paint.PaintData
function Interop.registerPaintItem(e)
    logAssert(type(e.id) == "string", "id must be a string")
    logAssert(type(e.paintTypes) == "table", "paintTypes must be a table")
    logger:debug("Registering paint item %s", e.id)
    e.id = e.id:lower()
    config.paintItems[e.id] = table.copy(e, {})
end

---@class JOP.BrushType
---@field id string The id of the brush type
---@field name string The name of the brush type

---@param e JOP.BrushType
function Interop.registerBrushType(e)
    logAssert(type(e.id) == "string", "id must be a string")
    logAssert(type(e.name) == "string", "name must be a string")
    logger:debug("Registering brush type %s", e.id)
    e.id = e.id:lower()
    config.brushTypes[e.id] = table.copy(e, {})
end

---@class JOP.Brush
---@field id string The id of the brush
---@field brushType string The brush type to use for this brush

---@param e JOP.Brush
function Interop.registerBrush(e)
    logAssert(type(e.id) == "string", "id must be a string")
    logAssert(type(e.brushType) == "string", "brushTypes must be a string")
    logger:debug("Registering brush %s", e.id)
    e.id = e.id:lower()
    config.brushes[e.id] = table.copy(e, {})
end

return Interop
