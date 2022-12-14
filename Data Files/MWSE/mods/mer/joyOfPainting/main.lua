local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("main")

require("mer.joyOfPainting.mcm")


local function initAll(path)
    path = "Data Files/MWSE/mods/mer/joyOfPainting/" .. path .. "/"
    for file in lfs.dir(path) do
        if common.isLuaFile(file) and not common.isInitFile(file) then
            logger:debug("Executing file: %s", file)
            dofile(path .. file)
        end
    end
end

logger:debug("Initialising Controllers")
initAll("controllers")
logger:debug("Initialising Interops")
initAll("interops")
logger:debug("Initialising activators")
initAll("activators")