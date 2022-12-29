local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("artStyle")
local interop = require("mer.joyOfPainting.interop")
local SkillService = require("mer.joyOfPainting.services.SkillService")

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
    brightness = {
        id = "brightness",
        shader = "jop_adjuster",
        name = "Brightness",
        sliderDefault = 50,
        shaderMin = -0.5,
        shaderMax = 0.5,
    },
    contrast = {
        id = "contrast",
        shader = "jop_adjuster",
        name = "Contrast",
        sliderDefault = 50,
        shaderMin = 0,
        shaderMax = 2,
    },
    saturation = {
        id = "saturation",
        shader = "jop_adjuster",
        name = "Saturation",
        sliderDefault = 50,
        shaderMin = 0,
        shaderMax = 2,
    },

    inkThickness = {
        id = "inkThickness",
        shader = "jop_ink",
        name = "Line Thickness",
        sliderDefault = 50,
        shaderMin = 0.0005,
        shaderMax = 0.0030,
    },
    distance = {
        id = "distance",
        shader = "jop_adjuster",
        name = "Background",
        sliderDefault = 100,
        shaderMin = 8,
        shaderMax = 500,
    }
}

---@type JOP.ArtStyle[]
local artStyles = {
    {
        name = "Oil Painting",
        ---@param image JOP.Image
        magickCommand = function(image)
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
                :resizeHard(image.canvasConfig.textureWidth, image.canvasConfig.textureHeight)
                :repage()
                :param(image.paintingPath)
                :execute(next)
                return true
            end
        end,
        shaders = {
            shaders.oil,
            shaders.adjuster,
        },
        controls = {
            controls.brightness,
            controls.contrast,
        },
        valueModifier = 15,
        animAlphaTexture = "Textures\\jop\\brush\\jop_paintingAlpha6.dds",
        equipment = {
            {
                toolId = "jop_brush_01",
                paintHolder = "jop_paint_01",
                consumesPaintHolder = false,
                paintConsumed = 10,
            }
        },
        requiresEasel = true,
    },

    {
        name = "Charcoal Drawing",
        magickCommand = function(image)
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
                :resizeHard(image.canvasConfig.textureWidth, image.canvasConfig.textureHeight)
                :gravity("center")
                :compositeClone(image.canvasConfig.canvasTexture, image.canvasConfig.textureWidth, image.canvasConfig.textureHeight)
                :repage()
                :param(image.paintingPath)
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
            controls.brightness,
            controls.contrast,
            controls.distance,
        },
        valueModifier = 1,
        equipment = {
            {
                toolId = "jop_brush_01",
                paintHolder = "jop_paint_01",
                consumesPaintHolder = false,
                paintConsumed = 10,
            }
        },
    },
    {
        name = "Ink Sketch",
        magickCommand = function(image)
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
                :resizeHard(image.canvasConfig.textureWidth, image.canvasConfig.textureHeight)
                --:blur(detailLevel)
                :gravity("center")
                :compositeClone(image.canvasConfig.canvasTexture, image.canvasConfig.textureWidth, image.canvasConfig.textureHeight)
                :repage()
                :param(image.paintingPath)
                :execute(next)
                return true
            end
        end,
        shaders = {
            shaders.ink,
            shaders.adjuster,
        },
        controls = {
            controls.contrast,
            controls.inkThickness,
        },
        valueModifier = 1.5,
        equipment = {
            {
                toolId = "jop_brush_01",
                paintHolder = "jop_paint_01",
                consumesPaintHolder = false,
                paintConsumed = 10,
            }
        },
    },
    {
        name = "Watercolor Painting",
        magickCommand = function(image)
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
                :resizeHard(image.canvasConfig.textureWidth, image.canvasConfig.textureHeight)
                :repage()
                :param(image.paintingPath)
                :execute(next)
                return true
            end
        end,
        shaders = {
            shaders.watercolor,
            shaders.adjuster,
        },
        controls = {
            controls.brightness,
            controls.contrast,
            controls.saturation,
        },
        valueModifier = 8,
        animAlphaTexture = "Textures\\jop\\brush\\jop_paintingAlpha6.dds",
        equipment = {
            {
                toolId = "jop_brush_01",
                paintHolder = "jop_paint_01",
                consumesPaintHolder = false,
                paintConsumed = 10,
            }
        },
        requiresEasel = true,
    }
}
event.register(tes3.event.initialized, function()
    for _, artStyle in ipairs(artStyles) do
        interop.registerArtStyle(artStyle)
    end
end)