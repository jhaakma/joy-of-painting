
local config = {}

--Static Config (stored right here)
config.modName = "The Joy of Painting Morrowind"
config.modDescription = [[
    The Joy of Painting Morrowind adds a new Painting skill which allows you to
    create your own paintings and sell them or hang them on a wall.
]]
config.configPath = "joyOfPainting"
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
    MIN_GOLD = 100,
    MAX_GOLD = 1000,
    MIN_SKILL = 10,
    MAX_SKILL = 100,
    MAX_RANDOM = 20.0
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
config.canvases = {}
config.easels = {}
config.artStyles = {}
config.paints = {}
config.easelActiveToMiscMap = {}
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
    logLevel = "INFO",
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