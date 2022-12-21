local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("artStyle")
local interop = require("mer.joyOfPainting.interop")
local SkillService = require("mer.joyOfPainting.services.SkillService")

---@type JoyOfPainting.ArtStyle[]
local artStyles = {
    {
        name = "Oil Painting",
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
                :paint(detailLevel)
                :resizeHard(image.canvas.textureWidth, image.canvas.textureHeight)
                :repage()
                :param(image.paintingPath)
                :execute(next)
                return true
            end
        end,
        shaders = {
            "jop_oil"
        },
        valueModifier = 10,
        soundEffect = "jop_brush_stroke_01",
        animAlphaTexture = "Textures\\jop\\brush\\jop_paintingAlpha6.dds",
        equipment = {
            {
                toolId = "jop_brush_01",
                paintHolder = "jop_paint_01",
                consumesPaintHolder = false,
                paintConsumed = 10,
            }
        }
    },

    {
        name = "Charcoal Sketch",
        magickCommand = function(image)
            local skill = SkillService.skills.painting.value
            logger:debug("Painting skill is %d", skill)
            local detailLevel = math.clamp(math.remap(skill,
                config.skillPaintEffect.MIN_SKILL, config.skillPaintEffect.MAX_SKILL,
                8, 4
            ), 8, 4)
            logger:debug("Charcoal Sketch detail level is %d", detailLevel)
            return function(next)
                image.magick:new("createCharoalSketch")
                :magick()
                :formatDDS()
                :param(image.screenshotPath)
                :trim()
                :autoGamma()
                :paint(detailLevel)
                --:blur(detailLevel)
                --:charcoal(tes3.player.data.charcoal or 1)
                :sketch()
                :brightnessContrast(-80, 90)
                :removeWhite(90)
                :resizeHard(image.canvas.textureWidth, image.canvas.textureHeight)
                :gravity("center")
                :compositeClone(image.canvas.canvasTexture, image.canvas.textureWidth, image.canvas.textureHeight)
                :repage()
                :param(image.paintingPath)
                :execute(next)
                return true
            end
        end,
        shaders = {
            --"jop_ink",
            --"jop_vignette",
            "jop_charcoal",
            "jop_greyscale"
        },
        valueModifier = 1,
        soundEffect = "jop_brush_stroke_01",
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
                5, 0
            ), 5, 0)
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
                :resizeHard(image.canvas.textureWidth, image.canvas.textureHeight)
                --:blur(detailLevel)
                :gravity("center")
                :compositeClone(image.canvas.canvasTexture, image.canvas.textureWidth, image.canvas.textureHeight)
                :repage()
                :param(image.paintingPath)
                :execute(next)
                return true
            end
        end,
        shaders = {
            "jop_ink",
        },
        valueModifier = 1,
        soundEffect = "jop_brush_stroke_01",
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
                :resizeHard(image.canvas.textureWidth, image.canvas.textureHeight)
                :repage()
                :param(image.paintingPath)
                :execute(next)
                return true
            end
        end,
        shaders = {
            "jop_watercolor"
        },
        valueModifier = 5,
        soundEffect = "jop_brush_stroke_01",
        animAlphaTexture = "Textures\\jop\\brush\\jop_paintingAlpha6.dds",
        equipment = {
            {
                toolId = "jop_brush_01",
                paintHolder = "jop_paint_01",
                consumesPaintHolder = false,
                paintConsumed = 10,
            }
        }
    }
}

for _, artStyle in ipairs(artStyles) do
    interop.registerArtStyle(artStyle)
end