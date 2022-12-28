--Add canvases via the interop
local interop = require("mer.joyOfPainting.interop")

---@type JoyOfPainting.Canvas[]
local canvases = {
    {
        canvasId = "jop_canvas_square_01",
        textureWidth = 512,
        textureHeight = 512,
        frameSize = "square",
        valueModifier = 10,
        canvasTexture = "Data Files\\Textures\\jop\\ab_painting_canvas_01.dds",
        requiresEasel = true,
    },
    {
        canvasId = "jop_canvas_tall_01",
        textureWidth = 512,
        textureHeight = 1024,
        frameSize = "tall",
        valueModifier = 10,
        canvasTexture = "Data Files\\Textures\\jop\\ab_painting_canvas_01.dds",
        requiresEasel = true,
    },
    {
        canvasId = "jop_canvas_wide_01",
        textureWidth = 1024,
        textureHeight = 512,
        frameSize = "wide",
        valueModifier = 10,
        canvasTexture = "Data Files\\Textures\\jop\\ab_painting_canvas_01.dds",
        requiresEasel = true,
    },

    {
        canvasId = "sc_paper plain",
        meshOverride = "meshes\\jop\\medium\\paper_01.nif",
        textureWidth = 512,
        textureHeight = 512,
        frameSize = "paper_portrait",
        valueModifier = 1,
        canvasTexture = "Data Files\\Textures\\tx_paper_plain_01.dds",
    }
}

event.register(tes3.event.initialized, function()
    ---@type JoyOfPainting.ArtStyle[]
    for _, canvas in ipairs(canvases) do
        interop.registerCanvas(canvas)
    end
end)

