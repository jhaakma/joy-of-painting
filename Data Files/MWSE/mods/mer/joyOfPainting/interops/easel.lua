--Add canvases via the interop
local interop = require("mer.joyOfPainting.interop")
local easel = {
    {
        id = "jop_easel_01",
    },
    {
        id = "jop_field_easel",
        doesPack = true,
        miscItem = "jop_easel_pack"
    },
}
event.register(tes3.event.initialized, function()
    for _, data in ipairs(easel) do
        interop.Easel.registerEasel(data)
    end
end)