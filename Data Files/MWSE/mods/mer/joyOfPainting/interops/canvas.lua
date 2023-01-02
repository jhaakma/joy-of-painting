--Add canvases via the interop
local interop = require("mer.joyOfPainting.interop")

---@type JOP.Canvas[]
local canvases = {
    {
        canvasId = "jop_canvas_square_01",
        textureWidth = 512,
        textureHeight = 512,
        frameSize = "square",
        valueModifier = 1.1,
        canvasTexture = "Data Files\\Textures\\jop\\ab_painting_canvas_01.dds",
        requiresEasel = true,
        animSpeed = 6.5,
        animSound = "jop_brush_stroke_01"
    },
    {
        canvasId = "jop_canvas_tall_01",
        rotatedId = "jop_canvas_wide_01",
        textureWidth = 512,
        textureHeight = 1024,
        frameSize = "tall",
        valueModifier = 1.1,
        canvasTexture = "Data Files\\Textures\\jop\\ab_painting_canvas_01.dds",
        requiresEasel = true,
        animSpeed = 6.5,
        animSound = "jop_brush_stroke_01"
    },
    {
        canvasId = "jop_canvas_wide_01",
        rotatedId = "jop_canvas_tall_01",
        textureWidth = 1024,
        textureHeight = 512,
        frameSize = "wide",
        valueModifier = 1.1,
        canvasTexture = "Data Files\\Textures\\jop\\ab_painting_canvas_01.dds",
        requiresEasel = true,
        animSpeed = 6.5,
        animSound = "jop_brush_stroke_01"
    },
    {
        canvasId = "sc_paper plain",
        meshOverride = "meshes\\jop\\medium\\paper_01.nif",
        textureWidth = 512,
        textureHeight = 512,
        frameSize = "paper_portrait",
        valueModifier = 1,
        canvasTexture = "Data Files\\Textures\\tx_paper_plain_01.dds",
        animSpeed = 2.0,
        animSound = "jop_scribble_01"
    },
    {
        canvasId = "jop_parchment_01",
        textureWidth = 512,
        textureHeight = 512,
        frameSize = "paper_portrait",
        valueModifier = 1.1,
        canvasTexture = "Data Files\\textures\\jop\\parchment.dds",
        animSound = "jop_scribble_01",
        animSpeed = 2.0,
    }
}

event.register(tes3.event.initialized, function()
    ---@type JOP.ArtStyle[]
    for _, canvas in ipairs(canvases) do
        interop.Painting.registerCanvas(canvas)
    end
end)

