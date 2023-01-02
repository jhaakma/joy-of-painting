local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("AshfallInterop")
local Easel = require("mer.joyOfPainting.items.Easel")
local Painting = require("mer.joyOfPainting.items.Painting")
local ArtStyle = require("mer.joyOfPainting.items.ArtStyle")
local UIHelper = require("mer.joyOfPainting.services.UIHelper")

local function hasCanvas(e)
    return Easel:new(e.reference):hasCanvas()
end

local function hasPainting(e)
    return Easel:new(e.reference):hasPainting()
end

local function hasEmptyCanvas(e)
    local easel = Easel:new(e.reference)
    return easel and easel:hasCanvas() and not easel:hasPainting()
end

local function canAttachCanvas(e)
    return Easel:new(e.reference):canAttachCanvas()
end

local bushcraftingSkillReq = {
    {
        skill = "Bushcrafting",
        requirement = 20,
    }
}

local recipes = {
    {
        id = "jop_frame_sq_01",
        description = "A square wooden frame, activate to attach a painting",
        materials = {
            { material = "wood", count = 4 },
            { material = "rope", count = 1 },
        },
        skillRequirements = bushcraftingSkillReq,
        category = "Painting",
        soundType = "wood",
        maxSteepness = 0.1,
    },
    {
        id = "jop_frame_w_01",
        description = "A wide wooden frame, activate to attach a painting",
        materials = {
            { material = "wood", count = 4 },
            { material = "rope", count = 1 },
        },
        skillRequirements = bushcraftingSkillReq,
        category = "Painting",
        soundType = "wood",
        maxSteepness = 0.1,
    },
    {
        id = "jop_frame_t_01",
        description = "A tall wooden frame, activate to attach a painting",
        materials = {
            { material = "wood", count = 4 },
            { material = "rope", count = 1 },
        },
        skillRequirements = bushcraftingSkillReq,
        category = "Painting",
        soundType = "wood",
        maxSteepness = 0.1,
    },
    {
        id = "jop_easel_01",
        description = "A crude wooden easel. Can be used to paint a canvas.",
        materials = {
            { material = "wood", count = 6 },
            { material = "rope", count = 4}
        },
        skillRequirements = bushcraftingSkillReq,
        destroyCallback = function(_recipe, e)
            local reference = e.reference
            local easel = Easel:new(reference)
            if easel and easel.painting and easel.data.canvasId then
                easel.painting:takeCanvas{blockSound = true}
            end
        end,
        category = "Painting",
        soundType = "wood",
        maxSteepness = 0.1,
        additionalMenuOptions = {
            {
                text = "Paint",
                callback = function(e)
                    local buttons = {}
                    for _, artStyleData in pairs(config.artStyles) do
                        local artStyle = ArtStyle:new(artStyleData)
                        table.insert(buttons, artStyle:getButton(function()
                            Easel:new(e.reference):paint(artStyle.name)
                        end))
                    end
                    tes3ui.showMessageMenu{
                        text = "Select Art Style",
                        buttons = buttons,
                        cancels = true
                    }
                end,
                enableRequirements = function(e)
                    return hasCanvas(e) and not hasPainting(e)
                end,
                tooltipDisabled = function(e)
                    if hasCanvas(e) and not hasPainting(e) then
                        return {
                            text = "Attach a canvas to the easel first."
                        }
                    else
                        return {
                            text = "You must scrape off the current painting first."
                        }
                    end
                end
            },
            { --DISABLED
                text = "Scrape Painting",
                callback = function(e)
                    local safeRef = tes3.makeSafeObjectHandle(e.reference)
                    if safeRef == nil then
                        logger:warn("Unable to scrape painting: Easel reference is no longer valid")
                        return
                    end
                    timer.delayOneFrame(function()
                        UIHelper.scrapePaintingMessage(function()
                            if safeRef:valid() then
                                Painting:new{
                                    reference = safeRef:getObject()
                                }:cleanCanvas()
                            else
                                logger:warn("Unable to clean canvas: Easel reference is no longer valid")
                            end
                        end)
                    end)
                end,
                showRequirements = function() return false end --hasPainting,
            },
            {
                text = "Attach Canvas",
                callback = function(e)
                    Easel:new(e.reference):openAttachCanvasMenu()
                end,
                showRequirements = canAttachCanvas,
            },
            {
                text = "Take Canvas",
                callback = function(e)
                    Easel:new(e.reference).painting:takeCanvas()
                end,
                showRequirements = hasEmptyCanvas,
            },
            {
                text = "Take Painting",
                callback = function(e)
                    Easel:new(e.reference).painting:takeCanvas()
                end,
                showRequirements = hasPainting,
            }
        }
    },
    {
        id = "jop_canvas_square_01",
        description = "A square canvas. Place on an easel to start painting.",
        category = "Painting",
        soundType = "fabric",
        skillRequirements = {
            {
                skill = "Bushcrafting",
                requirement = 20,}
        },
        materials = {
            { material = "fibre", count = 20 },
            { material = "resin", count = 1 }
        },
        rotationAxis = 'y'
    },
    {
        id = "jop_canvas_tall_01",
        description = "A tall canvas. Place on an easel to start painting.",
        category = "Painting",
        soundType = "fabric",
        skillRequirements = bushcraftingSkillReq,
        materials = {
            { material = "fibre", count = 20 },
            { material = "resin", count = 1 }
        },
        rotationAxis = 'y'
    },
    {
        id = "jop_canvas_wide_01",
        description = "A wide canvas. Place on an easel to start painting.",
        category = "Painting",
        soundType = "fabric",
        skillRequirements = bushcraftingSkillReq,
        materials = {
            { material = "fibre", count = 20 },
            { material = "resin", count = 1 }
        },
        rotationAxis = 'y'
    },
    {
        id = "jop_sketchbook_01",
        description = "A sketchbook to store drawings and sketches.",
        category = "Painting",
        soundType = "leather",
        skillRequirements = bushcraftingSkillReq,
        materials = {
            { material = "leather", count = 1 },
            { material = "paper", count = 2 }
        },
        rotationAxis = 'y'
    },

    {
        id = "jop_brush_01",
        description = "A brush for painting.",
        category = "Painting",
        soundType = "wood",
        skillRequirements = bushcraftingSkillReq,
        materials = {
            { material = "wood", count = 1 },
            { material = "fibre", count = 1 },
        },
    },

    {
        id = "jop_oil_palette_01",
        description = "A palette for mixing oil paints.",
        category = "Painting",
        soundType = "wood",
        skillRequirements = bushcraftingSkillReq,
        materials = {
            { material = "wood", count = 2 },
            { material = "ingred_fire_salts_01", count = 1 },
            { material = "ingred_frost_salts_01", count = 1 },
            { material = "ingred_ash_salts_01", count = 1 },
        },
        rotationAxis = 'y'
    }

    -- {
    --     id = "jop_coal_sticks_01",
    --     description = "Carved sticks of charcoal used for sketching.",
    --     category = "Painting",
    --     soundType = "carve",
    --     skillRequirements = bushcraftingSkillReq,
    --     materials = {
    --         { material = "coal", count = 4 }
    --     },
    --     toolRequirements = {
    --         {
    --             tool = "knife",
    --             equipped = true,
    --             conditionPerUse = 1
    --         }
    --     },
    -- }
}

local materials = {
    {
        id = "paper",
        name = "Paper",
        ids = {
            "sc_paper plain",
            "jop_paper_01",
        }
    },
}
local CraftingFramework = include("CraftingFramework")
if CraftingFramework then
    CraftingFramework.Material:registerMaterials(materials)
end

---@param e MenuActivatorRegisteredEvent
local function registerAshfallRecipes(e)
    local bushcraftingActivator = e.menuActivator
    if bushcraftingActivator then
        bushcraftingActivator:registerRecipes(recipes)
    end
end
event.register("Ashfall:ActivateBushcrafting:Registered", registerAshfallRecipes)

