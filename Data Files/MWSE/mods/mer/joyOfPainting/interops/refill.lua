local interop = require("mer.joyOfPainting.interop")
local refills = {
    {
        --Red, blue and yellow dye
        paintType = "watercolor",
        requiredItems = {
            "jop_dye_blue",
            "jop_dye_red",
            "jop_dye_yellow",
        }
    },
    {
        --Red, blue and yellow dye
        paintType = "oil",
        requiredItems = {
            "jop_dye_blue",
            "jop_dye_red",
            "jop_dye_yellow",
        }
    }
}
for _, refill in ipairs(refills) do
    interop.Refill.registerRefill(refill)
end