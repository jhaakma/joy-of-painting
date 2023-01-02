local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Frame")

local Frame = {
    classname = "Frame",
}

--[[
    Register a frame size, which allows canvases to have the right frame
]]
function Frame.registerFrameSize(e)
    common.logAssert(logger, type(e.id) == "string", "id must be a string")
    common.logAssert(logger, type(e.width) == "number", "width must be a number")
    common.logAssert(logger, type(e.height) == "number", "aspectRatio.height must be a number")
    logger:debug("Registering frame size %s", e.id)
    e.id = e.id:lower()
    config.frameSizes[e.id] = table.copy(e, {
        aspectRatio = e.width / e.height,
    })
    assert(math.isclose(config.frameSizes[e.id].aspectRatio, e.width / e.height) )
end

function Frame.registerFrame(e)
    common.logAssert(logger, type(e.id) == "string", "id must be a string")
    common.logAssert(logger, type(e.frameSize) == "string", "frameSize must be a string")
    logger:debug("Registering frame %s", e.id)
    e.id = e.id:lower()
    config.frames[e.id] = table.copy(e, {})
end

return Frame