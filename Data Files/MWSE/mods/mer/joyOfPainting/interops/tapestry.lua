local Tapestry = require("mer.joyOfPainting.items.Tapestry")
local tapestries = {
    { id = "furn_com_tapestry_01" },
    { id = "furn_com_tapestry_02" },
    { id = "furn_com_tapestry_03" },
    { id = "furn_com_tapestry_04" },
    { id = "furn_com_tapestry_05" },
    { id = "furn_de_tapestry_01" },
    { id = "furn_de_tapestry_02" },
    { id = "furn_de_tapestry_03" },
    { id = "furn_de_tapestry_04" },
    { id = "furn_de_tapestry_05" },
    { id = "furn_de_tapestry_06" },
    { id = "furn_de_tapestry_07" },
    { id = "furn_de_tapestry_08" },
    { id = "furn_de_tapestry_09" },
    { id = "furn_de_tapestry_10" },
    { id = "furn_de_tapestry_11" },
    { id = "furn_de_tapestry_12" },
    { id = "furn_de_tapestry_13" },
    { id = "furn_de_tapestry_m_01" },
    { id = "furn_s_tapestry" },
    { id = "furn_s_tapestry02" },
    { id = "furn_s_tapestry03" },
}
event.register(tes3.event.initialized, function()
    for _, tapestry in ipairs(tapestries) do
        Tapestry.registerTapestry(tapestry)
    end
end)