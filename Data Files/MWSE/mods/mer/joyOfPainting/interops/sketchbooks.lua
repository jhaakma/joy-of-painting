local interop = require("mer.joyOfPainting.interop")
local sketchbooks = {
    {
        id = "jop_sketchbook_01"
    }
}
for _, sketchbook in ipairs(sketchbooks) do
    interop.registerSketchbook(sketchbook)
end
