local interop = require("mer.joyOfPainting.interop")
local Dye = require("mer.joyOfPainting.items.Dye")
local Palette = require("mer.joyOfPainting.items.Palette")
---@type JOP.Refill[]
local refills = {
    {
        --Red, blue and yellow dye
        paintType = "watercolor",
        recipe = {
            name = "Plant Pigments",
            id = "jop_watercolor_refill",
            description = "Refill the palette using red, blue and yellow dye from gathered flowers and plants",
            materials = {
                {
                    material = "red_pigment",
                    quantity = 1,
                },
                {
                    material = "blue_pigment",
                    quantity = 1,
                },
                {
                    material = "yellow_pigment",
                    quantity = 1,
                },
            },
            knownByDefault = true,
            customRequirements = Dye.customRequirements,
            noResult = true,
            craftCallback = function()
                mwse.log("Refill callback")
                Dye.craftCallback()
                local paletteToRefill = Palette.getPaletteToRefill()
                if paletteToRefill then
                    paletteToRefill:doRefill()
                else
                    mwse.log("no palette to refill")
                end
            end,
        }
    }
}
event.register(tes3.event.initialized, function()
    for _, refill in ipairs(refills) do
        interop.Refill.registerRefill(refill)
    end
end)