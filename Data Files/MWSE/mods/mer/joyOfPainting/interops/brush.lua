local interop = require("mer.joyOfPainting.interop")

local brushes = {
    {
        id = "misc_quill",
        brushType = "quill",
    },
    {
        id = "sx2_quillSword",
        brushType = "quill",
    },
    {
        id = "jop_brush_01",
        brushType = "brush",
    },
    {
        id = "t_com_paintbrush_01",
        brushType = "brush",
    },
    {
        id = "t_com_paintbrush_02",
        brushType = "brush",
    },
    {
        id = "t_com_paintbrush_03",
        brushType = "brush",
    },
    {
        id = "t_com_paintbrush_04",
        brushType = "brush",
    },
    {
        id = "t_com_paintbrush_04r",
        brushType = "brush",
    },
    {
        id = "t_com_paintbrush_04g",
        brushType = "brush",
    },
    {
        id = "t_com_paintbrush_04b",
        brushType = "brush",
    },
    {
        id = "t_com_paintbrush_04y",
        brushType = "brush",
    },
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
event.register(tes3.event.initialized, function()
    for _, brush in ipairs(brushTypes) do
        interop.Brush.registerBrushType(brush)
    end
    for _, brush in ipairs(brushes) do
        interop.Brush.registerBrush(brush)
    end
end)