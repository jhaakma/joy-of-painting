
local config = {}

--Static Config (stored right here)
config.modName = "The Joy of Painting Morrowind"
config.modDescription = [[
    The Joy of Painting Morrowind adds a new Painting skill which allows you to
    create your own paintings and sell them or hang them on a wall.
]]
config.configPath = "joyOfPainting"
config.dependencies = {
    {
        name = "Skills Module",
        luaFile = "OtherSkills.skillModule",
        url = "https://www.nexusmods.com/morrowind/mods/46034?tab=files"
    },
    {
        name = "The Crafting Framework",
        versionFile = "CraftingFramework/version.txt",
        version = ">=v1.0.25",
        url = "https://www.nexusmods.com/morrowind/mods/51009?tab=files"
    },
}
config.ANIM_OFFSET = 2.0
config.skills = {
    painting = {
        id = "painting",
        name = "Painting",
        value = 10,
        description = "The Painting skill determines your ability to paint on a canvas. As the skill increases, your paintings become more detailed, and can sell for a higher price.",
        icon = "Icons/jop/paintskill.dds",
        specialization = tes3.specialization.magic,
        attribute = tes3.attribute.personality,
    }
}

config.BASE_PRICE = 2
config.MAX_RANDOM_PRICE_EFFECT = 1.5
--Configs for how much the painting skill affects the quality of the painting
config.skillPaintEffect = {
    MAX_RADIUS = 8.0,
    MIN_RADIUS = 0.0,
    MIN_SKILL = 10,
    MAX_SKILL = 60,
    MAX_RANDOM = 2.0
}
--Configs for how much the painting skill affects the value of the painting
config.skillGoldEffect = {
    MIN_EFFECT = 1,
    MAX_EFFECT = 30,
    MIN_SKILL = 10,
    MAX_SKILL = 100,
}
config.skillProgress = {
    BASE_PROGRESS_PAINTING = 30,
    NEW_REGION_MULTI = 3.0,
    MAX_RANDOM = 10.0
}

--File locations
local root = io.popen("cd"):read()
config.locations = {}
do
    config.locations.dataFiles = root .. "\\Data Files\\"
    config.locations.screenshot = config.locations.dataFiles .. "Textures\\jop\\sreenshot.png"
    config.locations.paintingsDir = config.locations.dataFiles .. "Textures\\jop\\p\\"
    config.locations.iconsDir = config.locations.dataFiles .. "Icons\\jop\\"
    config.locations.paintingIconsDir = config.locations.iconsDir .. "p\\"
    config.locations.frameIconsDir = config.locations.iconsDir .. "f\\"
    config.locations.sketchTexture = config.locations.dataFiles .. "Textures\\jop\\pencil_tile.png"
end

--Registered objects
---@type table<string, JOP.BackPack.Config>
config.backpacks = {}
---@type JOP.Canvas[]
config.canvases = {}
config.frameSizes = {}
config.frames = {}
config.easels = {}
config.miscEasels = {}
---@type table<string, JOP.ArtStyle.data>
config.artStyles = {}
config.controls = {}
---@type table<string, JOP.PaintType>
config.paintTypes = {}
---@type table<string, JOP.PaletteItem>
config.paletteItems = {}
---@type table<string, JOP.Refill[]>
config.refills = {}
---@type table<string, JOP.BrushType>
config.brushTypes = {}
---@type table<string, JOP.Brush>
config.brushes = {}
config.easelActiveToMiscMap = {}
config.meshOverrides = {}
config.sketchbooks = {}
config.paperMolds = {
    jop_paper_mold = {
        hoursToDry = 4,
        paperId = "sc_paper plain",
        paperPerPulp = 5,
    }
}
config.paperPulps = {
    jop_paper_pulp = true
}
config.tapestries = {
    furn_com_tapestry_01 = true,
    furn_com_tapestry_02 = true,
    furn_com_tapestry_03 = true,
    furn_com_tapestry_04 = true,
    furn_com_tapestry_05 = true,
    furn_de_tapestry_01 = true,
    furn_de_tapestry_02 = true,
    furn_de_tapestry_03 = true,
    furn_de_tapestry_04 = true,
    furn_de_tapestry_05 = true,
    furn_de_tapestry_06 = true,
    furn_de_tapestry_07 = true,
    furn_de_tapestry_08 = true,
    furn_de_tapestry_09 = true,
    furn_de_tapestry_10 = true,
    furn_de_tapestry_11 = true,
    furn_de_tapestry_12 = true,
    furn_de_tapestry_13 = true,
    furn_de_tapestry_m_01 = true,
    furn_s_tapestry = true,
    furn_s_tapestry02 = true,
    furn_s_tapestry03 = true,
}
config.shaders = {
    watercolor = "jop_watercolor",
    oil = "jop_oil",
    vignette = "jop_vignette",
    adjuster = "jop_adjuster",
    window = "jop_window",
    greyscale = "jop_greyscale",
    sketch = "jop_sketch",
}

local persistentDefault = {
    zoom = 100,
    brightness = 50,
    contrast = 50,
    saturation = 50,
}
local mcmDefault = {
    enabled = true,
    logLevel = "DEBUG", --TODO: Change to INFO before full release
    savedPaintingIndexes = {},
    maxSavedPaintings = 20,
    savedPaintingSize = 1080,
    enableTapestryRemoval = true,
}
--MCM Config (stored as JSON)
config.mcm = mwse.loadConfig(config.configPath, mcmDefault)
config.save = function()
    mwse.saveConfig(config.configPath, config.mcm)
end
--Persistent Configs (Stored on tes3.player.data, save specific)
config.persistent = setmetatable({}, {
    __index = function(_, key)
        if not tes3.player then return end
        tes3.player.data[config.configPath] = tes3.player.data[config.configPath] or persistentDefault
        return tes3.player.data[config.configPath][key]
    end,
    __newindex = function(_, key, value)
        if not tes3.player then return end
        tes3.player.data[config.configPath] = tes3.player.data[config.configPath] or persistentDefault
        tes3.player.data[config.configPath][key] = value
    end
})

return config