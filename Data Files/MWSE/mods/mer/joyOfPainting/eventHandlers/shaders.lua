

local config = require("mer.joyOfPainting.config")
local ShaderService = require("mer.joyOfPainting.services.ShaderService")
local PhotoMenu = require("mer.joyOfPainting.services.PhotoMenu")

event.register("loaded", function()
    for _, shader in pairs(config.shaders) do
        ShaderService.disable(shader.shaderId)
    end
end)