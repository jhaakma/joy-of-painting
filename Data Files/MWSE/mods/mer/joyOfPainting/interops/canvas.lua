--Add canvases via the interop

local common = require("mer.joyOfPainting.common")
local interop = require("mer.joyOfPainting.interop")

---@type JoyOfPainting.Canvas[]
local canvases = {
    {
        canvasId = "jop_canvas_square_01",
        textureWidth = 512,
        textureHeight = 512,
        canvasWidth = 1,
        canvasHeight = 1,
        valueModifier = 10,
        canvasTexture = "Data Files\\Textures\\jop\\ab_painting_canvas_01.dds",
    },
    {
        canvasId = "jop_canvas_tall_01",
        textureWidth = 512,
        textureHeight = 1024,
        canvasWidth = 9,
        canvasHeight = 16,
        valueModifier = 10,
        canvasTexture = "Data Files\\Textures\\jop\\ab_painting_canvas_01.dds",
    },
    {
        canvasId = "jop_canvas_wide_01",
        textureWidth = 1024,
        textureHeight = 512,
        canvasWidth = 16,
        canvasHeight = 9,
        valueModifier = 10,
        canvasTexture = "Data Files\\Textures\\jop\\ab_painting_canvas_01.dds",
    },
}

---@type JoyOfPainting.ArtStyle[]
for _, canvas in ipairs(canvases) do
    interop.registerCanvas(canvas)
end