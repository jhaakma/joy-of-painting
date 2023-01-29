local interop = require("mer.joyOfPainting.interop")
local sketchbooks = {
    {
        id = "jop_sketchbook_01"
    }
}
event.register(tes3.event.initialized, function()
    for _, sketchbook in ipairs(sketchbooks) do
        interop.Sketchbook.registerSketchbook(sketchbook)
    end
end)