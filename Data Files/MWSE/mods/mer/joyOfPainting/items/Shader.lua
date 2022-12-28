local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Shader")

local Shader = {}

function Shader:new(e)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.e = e
    return o
end