local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("artStyle")
local JoyOfPainting = require("mer.joyOfPainting")
local SkillService = require("mer.joyOfPainting.services.SkillService")
local PaintService = require("mer.joyOfPainting.services.PaintService")

local shaders = {
    { id = "adjuster", shaderId = "jop_adjuster" },
    { id = "charcoal", shaderId = "jop_charcoal" },
    { id = "greyscale", shaderId = "jop_greyscale" },
    { id = "blackAndWhite", shaderId = "jop_blackwhite" },
    { id = "ink", shaderId = "jop_ink" },
    { id = "oil", shaderId = "jop_oil" },
    { id = "sketch", shaderId = "jop_sketch" },
    { id = "vignette", shaderId = "jop_vignette" },
    { id = "watercolor", shaderId = "jop_watercolor" },
    { id = "window", shaderId = "jop_window" },
    { id = "detail", shaderId = "jop_kuwahara" },
    { id = "splash", shaderId = "jop_splash" },
    { id = "distort", shaderId = "jop_distort" },
    { id = "fogColor", shaderId = "jop_fog_color" },
    { id = "fogBW", shaderId = "jop_fog_bw" },
}

---@type JOP.ArtStyle.control[]
local controls = {
    {
        id = "brightness",
        uniform = "brightness",
        shader = "jop_adjuster",
        name = "Brightness",
        sliderDefault = 50,
        shaderMin = -0.25,
        shaderMax = 0.25,
    },
    {
        id = "detail",
        uniform = "contrast",
        shader = "jop_ink",
        name = "Detail",
        sliderDefault = 50,
        shaderMin = 0.1,
        shaderMax = 1.9,
    },
    {
        id = "canvasStrength",
        uniform = "canvas_strength",
        shader = "jop_splash",
        name = "Canvas Strength",
        sliderDefault = 50,
        shaderMin = 0.0,
        shaderMax = 1.0,
        calculate = function()
            return 0.7
        end
    },
    {
        id = "distortionStrength",
        uniform = "distortion_strength",
        shader = "jop_distort",
        name = "Distortion Strength",
        sliderDefault = 50,
        shaderMin = 0.0,
        shaderMax = 1.0,
        calculate = function(paintingSkill, artStyle)
            paintingSkill = math.clamp(paintingSkill, config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill)
            return math.remap(paintingSkill,
                config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill,
                0.008, 0.0
            )
        end
    },
    {
        id = "brushSize",
        uniform = "KernelSize",
        shader = "jop_kuwahara",
        name = "Detail",
        sliderDefault = 50,
        shaderMin = 1,
        shaderMax = 15,
        calculate = function(paintingSkill, artStyle)
            paintingSkill = math.clamp(paintingSkill, config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill)
            return math.remap(paintingSkill,
                config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill,
                (artStyle.maxBrushSize or 1), (artStyle.minBrushSize or 1)
            )
        end
    },
    {
        id = "contrast",
        uniform = "contrast",
        shader = "jop_adjuster",
        name = "Contrast",
        sliderDefault = 50,
        shaderMin = 0.5,
        shaderMax = 1.5,
    },
    {
        id = "saturation",
        uniform = "saturation",
        shader = "jop_adjuster",
        name = "Saturation",
        sliderDefault = 50,
        shaderMin = 0.5,
        shaderMax = 1.5,
    },

    {
        id = "inkThickness",
        uniform = "inkThickness",
        shader = "jop_ink",
        name = "Line Thickness",
        sliderDefault = 50,
        shaderMin = config.ink.THICKNESS_MIN,
        shaderMax = config.ink.THICKNESS_MAX,
        calculate = function(paintingSkill, artStyle)
            paintingSkill = math.clamp(paintingSkill, config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill)
            return math.remap(paintingSkill,
                config.skillPaintEffect.MIN_SKILL, artStyle.maxDetailSkill,
                artStyle.maxBrushSize, artStyle.minBrushSize
            )
        end
    },
    {
        id = "distanceBW",
        uniform = "distance",
        shader = "jop_fog_bw",
        name = "Fog",
        sliderDefault = 100,
        shaderMin = 8,
        shaderMax = 250,
    },

    {
        id = "distanceColor",
        uniform = "distance",
        shader = "jop_fog_color",
        name = "Fog",
        sliderDefault = 100,
        shaderMin = 8,
        shaderMax = 250,
    },
    {
        id = "inkDistance",
        uniform = "distance",
        shader = "jop_ink",
        name = "Fog",
        sliderDefault = 100,
        shaderMin = 8,
        shaderMax = 250,
    },
    {
        id = "bgColor",
        uniform = "bgColor",
        shader = "jop_fog_bw",
        name = "Fog Color",
        sliderDefault = 50,
        shaderMin = 0.05,
        shaderMax = 1,
        defaultValue = -1.0,
    },
    {
        id = "bgRed",
        uniform = "bgRed",
        shader = "jop_fog_color",
        name = "Fog Color: Red",
        sliderDefault = 50,
        shaderMin = 0.05,
        shaderMax = 1,
    },
    {
        id = "bgGreen",
        uniform = "bgGreen",
        shader = "jop_fog_color",
        name = "Fog Color: Green",
        sliderDefault = 50,
        shaderMin = 0.05,
        shaderMax = 1,
    },
    {
        id = "bgBlue",
        uniform = "bgBlue",
        shader = "jop_fog_color",
        name = "Fog Color: Blue",
        sliderDefault = 50,
        shaderMin = 0.05,
        shaderMax = 1,
    },
    {
        id = "threshold",
        uniform = "threshold",
        shader = "jop_blackwhite",
        name = "Threshold",
        sliderDefault = 50,
        shaderMin = 0.01,
        shaderMax = 1.9,
    },
    {
        id = "watercolorLut",
        uniform = "selectedLut",
        shader = "jop_watercolor",
        name = "Color Palette",
        sliderDefault = 1,
        sliderMin = 1,
        sliderMax = 9,
        shaderMin = 1,
        shaderMax = 9,
    },

    {
        id = "splashBlend",
        uniform = "blend_type",
        shader = "jop_splash",
        name = "Blend Type",
        sliderDefault = 1,
        sliderMin = 1,
        sliderMax = 5,
        shaderMin = 1,
        shaderMax = 5,
    }
}

---@type JOP.ArtStyle.data[]
local artStyles = {
    {
        name = "Charcoal Drawing",
        ---@param image JOP.Image
        magickCommand = function(image)
            local savedWidth, savedHeight = PaintService.getSavedPaintingDimensions(image)

            local skill = SkillService.skills.painting.current
            logger:debug("Painting skill is %d", skill)
            return function(next)
                image.magick:new("createCharoalSketch")
                :magick()
                :formatDDS()
                :param(image.screenshotPath)
                :trim()
                :removeWhite(50)
                :resizeHard(savedWidth, savedHeight)
                :gravity("center")
                :compositeClone(common.getCanvasTexture(image.canvasConfig.canvasTexture),
                    savedWidth, savedHeight, image.canvasConfig.baseRotation)
                :repage()
                :param(image.savedPaintingPath)
                :execute(next)
                return true
            end
        end,
        shaders = {
            "blackAndWhite",
            "detail",
            "adjuster",
            "fogBW",
            "charcoal",
        },
        controls = {
            "threshold",
            "distanceBW",
            "brushSize",
            "bgColor",
        },
        valueModifier = 1,
        paintType = "charcoal",
        maxDetailSkill = 30,
        minBrushSize = 1,
        maxBrushSize = 10,
        helpText = [[
Charcoal drawings work best with high contrast images against an empty background.

Use the fog setting to remove background elements and the threshold to adjust the contrast.
]]
    },
    {
        name = "Ink Sketch",
        magickCommand = function(image)
            local savedWidth, savedHeight = PaintService.getSavedPaintingDimensions(image)
            local skill = SkillService.skills.painting.current
            logger:debug("Painting skill is %d", skill)
            return function(next)
                image.magick:new("createInkSketch")
                :magick()
                :formatDDS()
                :param(image.screenshotPath)
                :trim()
                :autoGamma()
                :removeWhite(70)
                :resizeHard(savedWidth, savedHeight)
                :gravity("center")
                :compositeClone(common.getCanvasTexture(image.canvasConfig.canvasTexture),
                    savedWidth, savedHeight, image.canvasConfig.baseRotation)
                :repage()
                :param(image.savedPaintingPath)
                :execute(next)
                return true
            end
        end,
        shaders = {
            "ink",
            "adjuster",
        },
        controls = {
            "detail",
            "inkThickness",
            "inkDistance",
        },
        valueModifier = 1.5,
        paintType = "ink",
        maxDetailSkill = 40,
        minBrushSize = config.ink.THICKNESS_MIN,
        maxBrushSize = config.ink.THICKNESS_MAX,
        helpText = [[
Ink sketches are good for images with defined shapes.

Use the detail setting to adjust how dense the lines are, and the fog setting to remove background elements.
]]
    },
    {
        name = "Watercolor Painting",
        magickCommand = function(image)
            local savedWidth, savedHeight = PaintService.getSavedPaintingDimensions(image)
            local skill = SkillService.skills.painting.current
            logger:debug("Painting skill is %d", skill)
            return function(next)
                image.magick:new("Watercolor Painting")
                :magick()
                :formatDDS()
                :param(image.screenshotPath)
                :trim()
                :resizeHard(savedWidth, savedHeight)
                :compositeClone(common.getCanvasTexture(image.canvasConfig.canvasTexture),
                    savedWidth, savedHeight, image.canvasConfig.baseRotation)
                :repage()
                :param(image.savedPaintingPath)
                :execute(next)
                return true
            end
        end,
        shaders = {
            "detail",
            "watercolor",
            "splash",
            "distort",
            "adjuster",
            "fogColor",
        },
        controls = {
            "watercolorLut",
            "brightness",
            "contrast",
            "distanceColor",
            "bgRed",
            "bgGreen",
            "bgBlue",
            "canvasStrength",
            "brushSize",
            "distortionStrength",
            "splashBlend",
        },
        valueModifier = 4,
        animAlphaTexture = "Textures\\jop\\brush\\jop_paintingAlpha6.dds",
        paintType = "watercolor",
        --requiresEasel = true,
        maxDetailSkill = 50,
        minBrushSize = 5,
        maxBrushSize = 15,
        helpText = [[
Watercolor paintings have a limited color palette and thick brush strokes. They are good for making abstract and impressionist paintings.

Try replacing the background with the fog setting and changing the fog color to get interesting color combinations.
]]
    },
    {
        name = "Oil Painting",
        ---@param image JOP.Image
        magickCommand = function(image)
            local savedWidth, savedHeight = PaintService.getSavedPaintingDimensions(image)
            local skill = SkillService.skills.painting.current
            logger:debug("Painting skill is %d", skill)
            return function(next)
                image.magick:new("Oil Painting")
                :magick()
                :formatDDS()
                :param(image.screenshotPath)
                :trim()
                :resizeHard(savedWidth, savedHeight)
                :repage()
                :param(image.savedPaintingPath)
                :execute(next)
                return true
            end
        end,
        shaders = {
            "detail",
            "oil",
            "splash",
            "distort",
            "adjuster",
            "fogColor",
        },
        controls = {
            "brightness",
            "contrast",
            "distanceColor",
            "bgRed",
            "bgGreen",
            "bgBlue",
            "brushSize",
            "canvasStrength",
            "distortionStrength",
        },
        valueModifier = 9,
        animAlphaTexture = "Textures\\jop\\brush\\jop_paintingAlpha6.dds",
        paintType = "oil",
        requiresEasel = true,
        maxDetailSkill = 60,
        minBrushSize = 3,
        maxBrushSize = 10,
        helpText = [[
Oil paintings require high skill before they start looking detailed.

Reduce contrast for a more matte look, or increase contrast to create more defined paint lines.
]]
    },
}
event.register(tes3.event.initialized, function()
for _, shader in ipairs(shaders) do
        JoyOfPainting.ArtStyle.registerShader(shader)
    end
    for _, control in ipairs(controls) do
        JoyOfPainting.ArtStyle.registerControl(control)
    end
    for _, artStyle in ipairs(artStyles) do
        JoyOfPainting.ArtStyle.registerArtStyle(artStyle)
    end
    event.trigger("JoyOfPainting:ArtStyles")
end)