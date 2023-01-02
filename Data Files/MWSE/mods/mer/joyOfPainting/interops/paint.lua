local interop = require("mer.joyOfPainting.interop")

local paintItems = {
    {
        id = "ashfall_ingred_coal_01",
        paintTypes = {
            charcoal = true,
        },
        breaks = true,
        uses = 5,
    },
    {
        id = "t_ingmine_charcoal_01",
        paintTypes = {
            charcoal = true,
        },
        breaks = true,
        uses = 5,
    },
    {
        id = "jop_coal_sticks_01",
        paintTypes = {
            charcoal = true,
        },
        breaks = true,
        uses = 20,
    },
    {
        id = "misc_inkwell",
        paintTypes = {
            ink = true,
        },
        uses = 20,
    },
    {
        id = "jop_watercolor_palette_01",
        paintTypes = {
            watercolor = true,
        },
        uses = 20
    },
    {
        id = "Jop_oil_palette_01",
        paintTypes = {
            oil = true,
            watercolor = true,
        },
        uses = 15
    },
}

local paintTypes = {
    {
        id = "charcoal",
        name = "Charcoal",
        brushType = nil,
    },
    {
        id = "ink",
        name = "Ink",
        brushType = "quill",
    },
    {
        id = "watercolor",
        name = "Watercolor Paint",
        brushType = "brush",
    },
    {
        id = "oil",
        name = "Oil Paint",
        brushType = "brush",
    }
}

for _, item in ipairs(paintItems) do
    interop.registerPaintItem(item)
end
for _, paintType in ipairs(paintTypes) do
    interop.registerPaintType(paintType)
end
