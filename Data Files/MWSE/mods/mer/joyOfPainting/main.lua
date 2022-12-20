local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("main")

require("mer.joyOfPainting.mcm")

local function isLuaFile(file) return file:sub(-4, -1) == ".lua" end
local function isInitFile(file) return file == "init.lua" end
local function initAll(path)
    path = "Data Files/MWSE/mods/mer/joyOfPainting/" .. path .. "/"
    for file in lfs.dir(path) do
        if isLuaFile(file) and not isInitFile(file) then
            logger:debug("Executing file: %s", file)
            dofile(path .. file)
        end
    end
end

logger:debug("Initialising Controllers")
initAll("controllers")
logger:debug("Initialising Interops")
initAll("interops")