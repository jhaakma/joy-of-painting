local paintTypes = {
    {
        id = "charcoal",
        name = "Charcoal",
        paints = {
            ashfall_ingred_coal_01 = {
                breaks = true,
                uses = 5,
            },
            t_ingmine_charcoal_01 = {
                breaks = true,
                uses = 5,
            },
            jop_coal_sticks_01 = {
                breaks = true,
                uses = 20,
            },
        }
    },
    {
        id = "ink",
        name = "Ink",
        brushType = "quill",
        paints = {
            misc_inkwell = {
                uses = 20,
            }
        }
    },
    {
        id = "watercolor",
        name = "Watercolor Paint",
        brushType = "brush",
        paints = {
            jop_paint_watercolor = {
                uses = 20
            },

            --todo, remove when watercolor implemented
            jop_oil_palette_01 = {
                uses = 15
            }
        }
    },
    {
        id = "oil",
        name = "Oil Paint",
        brushType = "brush",
        paints = {
            jop_oil_palette_01 = {
                uses = 15
            }
        }
    }
}

local brushTypes = {
    {
        id = "quill",
        name = "Quill",
        brushes = {
            "misc_quill"
        }
    },
    {
        id = "brush",
        name = "Paintbrush",
        brushes = {
            "jop_brush_01"
        }
    }
}


local interop = require("mer.joyOfPainting.interop")
for _, paintType in ipairs(paintTypes) do
    interop.registerPaintType(paintType)
end
for _, brush in ipairs(brushTypes) do
    interop.registerBrushType(brush)
end