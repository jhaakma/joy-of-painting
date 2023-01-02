local interop = require("mer.joyOfPainting.interop")

local brushes = {
    {
        id = "misc_quill",
        brushType = "quill",
    },
    {
        id = "jop_brush_01",
        brushType = "brush",
    }
}

local brushTypes = {
    {
        id = "quill",
        name = "Quill",
    },
    {
        id = "brush",
        name = "Paintbrush",
    }
}
for _, brush in ipairs(brushTypes) do
    interop.registerBrushType(brush)
end
for _, brush in ipairs(brushes) do
    interop.registerBrush(brush)
end