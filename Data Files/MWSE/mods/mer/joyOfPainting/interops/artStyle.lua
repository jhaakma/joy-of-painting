local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("artStyle")
local interop = require("mer.joyOfPainting.interop")
local SkillService = require("mer.joyOfPainting.services.SkillService")
local PaintService = require("mer.joyOfPainting.services.PaintService")

local shaders = {
    oil = "jop_oil",
    watercolor = "jop_watercolor",
    ink = "jop_ink",
    adjuster = "jop_adjuster",
    charcoal = "jop_charcoal",
    greyscale = "jop_greyscale",
    vignette = "jop_vignette",
}

local controls = {
    {
        id = "brightness",
        uniform = "brightness",
        shader = "jop_adjuster",
        name = "Brightness",
        sliderDefault = 50,
        shaderMin = -0.5,
        shaderMax = 0.5,
    },
    {
        id = "contrast",
        uniform = "contrast",
        shader = "jop_adjuster",
        name = "Contrast",
        sliderDefault = 50,
        shaderMin = 0,
        shaderMax = 2,
    },
    {
        id = "saturation",
        uniform = "saturation",
        shader = "jop_adjuster",
        name = "Saturation",
        sliderDefault = 50,
        shaderMin = 0,
        shaderMax = 2,
    },

    {
        id = "inkThickness",
        uniform = "inkThickness",
        shader = "jop_ink",
        name = "Line Thickness",
        sliderDefault = 50,
        shaderMin = 0.0005,
        shaderMax = 0.0030,
    },
    {
        id = "distance",
        uniform = "distance",
        shader = "jop_adjuster",
        name = "Fog",
        sliderDefault = 100,
        shaderMin = 8,
        shaderMax = 500,
    },
    {
        id = "inkDistance",
        uniform = "distance",
        shader = "jop_ink",
        name = "Fog",
        sliderDefault = 100,
        shaderMin = 8,
        shaderMax = 500,
    },
    {
        id = "bgColor",
        uniform = "bgColor",
        shader = "jop_adjuster",
        name = "Fog Color",
        sliderDefault = 50,
        shaderMin = 0,
        shaderMax = 1,
    }
}

---@type JOP.ArtStyle.data[]
local artStyles = {
    {
        name = "Charcoal Drawing",
        ---@param image JOP.Image
        magickCommand = function(image)
            local savedWidth, savedHeight = PaintService.getSavedPaintingDimensions(image)

            local skill = SkillService.skills.painting.value
            logger:debug("Painting skill is %d", skill)
            local detailLevel = math.clamp(math.remap(skill,
                config.skillPaintEffect.MIN_SKILL, 40,
                10, 1
            ), 10, 1)
            logger:debug("Charcoal Sketch detail level is %d", detailLevel)
            return function(next)

                image.magick:new("createCharoalSketch")
                :magick()
                :formatDDS()
                :param(image.screenshotPath)
                :trim()
                :autoGamma()
                :blur(detailLevel)
                :paint(detailLevel)
                --:charcoal(tes3.player.data.charcoal or 1)
                :sketch()
                :brightnessContrast(-80, 90)
                :removeWhite(90)
                :resizeHard(savedWidth, savedHeight)
                :gravity("center")
                :compositeClone(image.canvasConfig.canvasTexture, savedWidth, savedHeight)
                :repage()
                :param(image.savedPaintingPath)
                :execute(next)
                return true
            end
        end,
        shaders = {
            shaders.charcoal,
            shaders.greyscale,
            shaders.adjuster,
        },
        controls = {
            "brightness",
            "contrast",
            "distance",
            "bgColor",
        },
        valueModifier = 1,
        paintType = "charcoal",
    },
    {
        name = "Ink Sketch",
        magickCommand = function(image)
            local savedWidth, savedHeight = PaintService.getSavedPaintingDimensions(image)
            local skill = SkillService.skills.painting.value
            logger:debug("Painting skill is %d", skill)
            local detailLevel = math.clamp(math.remap(skill,
                config.skillPaintEffect.MIN_SKILL, config.skillPaintEffect.MAX_SKILL,
                8, 1
            ), 8, 1)
            logger:debug("Ink Sketch detail level is %d", detailLevel)
            return function(next)
                image.magick:new("createInkSketch")
                :magick()
                :formatDDS()
                :param(image.screenshotPath)
                :trim()
                :autoGamma()
                :removeWhite(50)
                :paint(detailLevel)
                :resizeHard(savedWidth, savedHeight)
                --:blur(detailLevel)
                :gravity("center")
                :compositeClone(image.canvasConfig.canvasTexture, savedWidth, savedHeight)
                :repage()
                :param(image.savedPaintingPath)
                :execute(next)
                return true
            end
        end,
        shaders = {
            shaders.ink,
            shaders.adjuster,
        },
        controls = {
            "brightness",
            "inkThickness",
            "inkDistance",
        },
        valueModifier = 1.5,
        paintType = "ink",
    },
    {
        name = "Watercolor Painting",
        magickCommand = function(image)
            local savedWidth, savedHeight = PaintService.getSavedPaintingDimensions(image)
            local skill = SkillService.skills.painting.value
            logger:debug("Painting skill is %d", skill)
            local detailLevel = math.clamp(math.remap(skill,
                config.skillPaintEffect.MIN_SKILL, config.skillPaintEffect.MAX_SKILL,
                10, 2
            ), 10, 2)
            logger:debug("Watercolor Painting detail level is %d", detailLevel)
            return function(next)
                image.magick:new("createPainting")
                :magick()
                :formatDDS()
                :param(image.screenshotPath)
                :trim()
                --:autoGamma()
                :blur(detailLevel)
                :paint(detailLevel)
                :resizeHard(savedWidth, savedHeight)
                :repage()
                :param(image.savedPaintingPath)
                :execute(next)
                return true
            end
        end,
        shaders = {
            shaders.watercolor,
            shaders.adjuster,
        },
        controls = {
            "brightness",
            "contrast",
            "saturation",
        },
        valueModifier = 8,
        animAlphaTexture = "Textures\\jop\\brush\\jop_paintingAlpha6.dds",
        paintType = "watercolor",
        requiresEasel = true,
    },

    {
        name = "Oil Painting",
        ---@param image JOP.Image
        magickCommand = function(image)
            local savedWidth, savedHeight = PaintService.getSavedPaintingDimensions(image)
            local skill = SkillService.skills.painting.value
            logger:debug("Painting skill is %d", skill)
            local detailLevel = math.clamp(math.remap(skill,
                config.skillPaintEffect.MIN_SKILL, config.skillPaintEffect.MAX_SKILL,
                10, 0
            ), 10,0)
            logger:debug("Oil Painting detail level is %d", detailLevel)
            return function(next)
                image.magick:new("createPainting")
                :magick()
                :formatDDS()
                :param(image.screenshotPath)
                :trim()
                --:autoGamma()
                :blur(detailLevel)
                :paint(detailLevel)
                :resizeHard(savedWidth, savedHeight)
                :repage()
                :param(image.savedPaintingPath)
                :execute(next)
                return true
            end
        end,
        shaders = {
            shaders.oil,
            shaders.adjuster,
        },
        controls = {
            "brightness",
            "contrast",
        },
        valueModifier = 15,
        animAlphaTexture = "Textures\\jop\\brush\\jop_paintingAlpha6.dds",
        paintType = "oil",
        requiresEasel = true,
    },
}

event.register(tes3.event.initialized, function()
    for _, control in ipairs(controls) do
        interop.ArtStyle.registerControl(control)
    end
    for _, artStyle in ipairs(artStyles) do
        interop.ArtStyle.registerArtStyle(artStyle)
    end
end)