local ashfall = include("mer.ashfall.interop")
if not ashfall then return end
local Easel = require("mer.joyOfPainting.items.Easel")
local Dye = require("mer.joyOfPainting.items.Dye")
local recipes = {
    {
        id = "jop_frame_sq_01",
        description = "A square wooden frame, activate to attach a painting",
        materials = {
            { material = "wood", count = 4 },
            { material = "rope", count = 1 },
        },
        skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
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
        skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
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
        skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
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
        skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
        destroyCallback = function(_recipe, e)
            local reference = e.reference
            local easel = Easel:new(reference)
            if easel and easel:hasCanvas() then
                easel.painting:takeCanvas{blockSound = true}
            end
        end,
        category = "Painting",
        soundType = "wood",
        maxSteepness = 0.1,
        additionalMenuOptions = Easel.getActivationButtons(),
    },
    {
        id = "jop_canvas_square_01",
        description = "A square canvas. Place on an easel to start painting.",
        category = "Painting",
        soundType = "fabric",
        skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
        materials = {
            { material = "fabric", count = 2 },
            { material = "wood", count = 4 },
            { material = "resin", count = 1 }
        },
        rotationAxis = 'y'
    },
    {
        id = "jop_canvas_wide_01",
        description = "A wide canvas. Place on an easel to start painting.",
        category = "Painting",
        soundType = "fabric",
        skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
        materials = {
            { material = "fabric", count = 2 },
            { material = "wood", count = 4 },
            { material = "resin", count = 1 }
        },
        rotationAxis = 'y'
    },
    {
        id = "jop_sketchbook_01",
        description = "A sketchbook to store drawings and sketches.",
        category = "Painting",
        soundType = "leather",
        skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
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
        skillRequirements = {ashfall.bushcrafting.survivalTiers.apprentice},
        materials = {
            { material = "wood", count = 1 },
            { material = "fibre", count = 1 },
        },
        rotationAxis = 'x'
    },

    {
        id = "jop_oil_palette_01",
        description = "A palette for storing and mixing oil paints.",
        category = "Painting",
        soundType = "wood",
        skillRequirements = {ashfall.bushcrafting.survivalTiers.apprentice},
        materials = {
            { material = "wood", count = 2 },
        },
        rotationAxis = 'x'
    },

    {
        id = "jop_water_palette_01",
        description = "A palette for storing and mixing watercolor paints.",
        category = "Painting",
        soundType = "wood",
        skillRequirements = {ashfall.bushcrafting.survivalTiers.apprentice},
        materials = {
            { material = "wood", count = 2 },
        },
        rotationAxis = 'x'
    },

    {
        id = "jop_dye_blue",
        description = "Blue dye for refilling a watercolor palette.",
        category = "Painting",
        soundType = "carve",
        skillRequirements = {ashfall.bushcrafting.survivalTiers.apprentice},
        customRequirements = Dye.customRequirements,
        materials = {
            { material = "blue_pigment", count = 1 },
        },
        craftCallback = Dye.craftCallback
    },

    {
        id = "jop_dye_red",
        description = "Red dye for refilling a watercolor palette.",
        category = "Painting",
        soundType = "carve",
        skillRequirements = {ashfall.bushcrafting.survivalTiers.apprentice},
        customRequirements = Dye.customRequirements,
        materials = {
            { material = "red_pigment", count = 1 },
        },
        craftCallback = Dye.craftCallback
    },

    {
        id = "jop_dye_yellow",
        description = "Yellow dye for refilling a watercolor palette.",
        category = "Painting",
        soundType = "carve",
        skillRequirements = {ashfall.bushcrafting.survivalTiers.apprentice},
        customRequirements = Dye.customRequirements,
        materials = {
            { material = "yellow_pigment", count = 1 },
        },
        craftCallback = Dye.craftCallback
    },


    {
        id = "jop_paper_pulp",
        description = "A pile of paper pulp. Use with a paper mold to craft sheets of paper.",
        category = "Painting",
        soundType = "fabric",
        skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
        materials = {
            { material = "fibre", count = 4 },
        },
        customRequirements = {
            {
                getLabel = function() return "Water: 10 units" end,
                check = function()
                    ---@param stack tes3itemStack
                    for _, stack in pairs(tes3.player.object.inventory) do
                        if stack.variables then
                            for _, itemData in ipairs(stack.variables) do
                                local liquidContainer = ashfall.LiquidContainer.createFromInventory(stack.object, itemData)
                                local hasEnoughWater = liquidContainer ~= nil
                                    and liquidContainer:hasWater()
                                    and liquidContainer:isWater()
                                    and liquidContainer.waterAmount >= 10
                                if hasEnoughWater then
                                    return true
                                end
                            end
                        end
                    end
                    return false
                end
            },
        },
        craftCallback = function(e)
            ---@param stack tes3itemStack
            for _, stack in pairs(tes3.player.object.inventory) do
                if stack.variables then
                    for _, itemData in ipairs(stack.variables) do
                        local liquidContainer = ashfall.LiquidContainer.createFromInventory(stack.object, itemData)
                        local hasEnoughWater = liquidContainer ~= nil
                            and liquidContainer:hasWater()
                            and liquidContainer:isWater()
                            and liquidContainer.waterAmount >= 10
                        if liquidContainer ~= nil and hasEnoughWater then
                            liquidContainer:reduce(10)
                            return
                        end
                    end
                end
            end
        end
    },

    {
        id = "jop_paper_mold",
        description = "A mold for crafting sheets of paper.",
        category = "Painting",
        soundType = "fabric",
        skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
        materials = {
            { material = "wood", count = 2 },
            { material = "fibre", count = 1 },
        },
    }
}

local materials = {
    {
        id = "paper",
        name = "Paper",
        ids = {
            "sc_paper plain",
            "jop_parchment_01",
            "jop_paper_01",
        }
    },
    {
        id = "red_pigment",
        name = "Red Pigment",
        ids = {
            "ingred_fire_petal_01",
            "ingred_heather_01",
            "ingred_holly_01",
            "ingred_red_lichen_01",
            "ab_ingflor_bloodgrass_01",
            "ab_ingflor_bloodgrass_02",
            "mr_berries",
            "ingred_comberry_01",
            "Ingred_timsa-come-by_01",
            "Ingred_noble_sedge_01",
        },
    },
    {
        id = "blue_pigment",
        name = "Blue Pigment",
        ids = {
            "ingred_bc_coda_flower",
            "ingred_belladonna_01",
            "ingred_stoneflower_petals_01",
            "t_ingflor_lavender_01",
            "ab_ingflor_bluekanet_01",
            "ingred_wolfsbane_01",
            "Ingred_meadow_rye_01",
        },
    },
    {
        id = "yellow_pigment",
        name = "Yellow Pigment",
        ids = {
            "ingred_bittergreen_petals_01",
            "ingred_gold_kanet_01",
            "ingred_golden_sedge_01",
            "ingred_timsa-come-by_01",
            "ingred_wickwheat_01",
            "ingred_willow_anther_01",
        },
    }
}
event.register(tes3.event.initialized, function()
    local CraftingFramework = include("CraftingFramework")
    if CraftingFramework then
        CraftingFramework.Material:registerMaterials(materials)
    end
end)

---@param e MenuActivatorRegisteredEvent
local function registerAshfallRecipes(e)
    local activator = e.menuActivator
    if activator then
        activator:registerRecipes(recipes)
    end
end
event.register("Ashfall:ActivateBushcrafting:Registered", registerAshfallRecipes)

local function registerTanningRackRecipes(e)
    local activator = e.menuActivator
    if activator then
        activator:registerRecipes({
            {
                id = "jop_parchment_01",
                description = "Blank parchment made from animal hide, used for sketching.",
                materials = {
                    { material = "hide", count = 1 },
                },
                category = "Painting",
                soundType = "leather",
                skillRequirements = {ashfall.bushcrafting.survivalTiers.novice},
                toolRequirements = {
                    {
                        tool = "knife",
                        equipped = true,
                        conditionPerUse = 1
                    }
                },
                rotationAxis = "y",
                resultAmount = 4,
            }
        })
    end
end
event.register("Ashfall:ActivateTanningRack:Registered", registerTanningRackRecipes)