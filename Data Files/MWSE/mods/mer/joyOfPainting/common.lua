local common = {}

local config = require("mer.joyOfPainting.config")

local MWSELogger = require("logging.logger")
local CraftingFramework = require("CraftingFramework")

---@type table<string, MWSELogger>
common.loggers = {}

function common.createLogger(serviceName)
    local logger = MWSELogger.new{
        name = string.format("JoyOfPainting - %s", serviceName),
        logLevel = config.mcm.logLevel
    }
    common.loggers[serviceName] = logger
    return logger
end
local logger = common.createLogger("common")

function common.getVersion()
    local version = ""
    local versionFile = io.open("Data Files/MWSE/mods/mer/joyOfPainting/version.txt", "r")
    if versionFile then
        for line in versionFile:lines() do -- Loops over all the lines in an open text file
            version = line
            break
        end
    end
    return version
end

---@param reference tes3reference
---@return boolean
function common.isStack(reference)
    return (
        reference.attachments and
        reference.attachments.variables and
        reference.attachments.variables.count > 1
    )
end

function common.isShiftDown()
    return tes3.worldController.inputController:isKeyDown(tes3.scanCode.lShift)
end

---@param target tes3reference
function common.pickUp(target)
    tes3.addItem({
        reference = tes3.player,
        item = target.object --[[@as JOP.tes3itemChildren]],
        count = 1,
        itemData = target.itemData,
    })
    target.itemData = nil
    target:delete()
end

function common.closeEnough(reference)
    return reference.position:distance(tes3.player.position) < tes3.getPlayerActivationDistance()
end

function common.logAssert(logger, condition, message)
    if not condition then
        logger:error(message)
        assert(condition, message)
    end
end

function common.disablePlayerControls()
    logger:debug("Disabling player controls")
    --disable everything except vanity
    tes3.setPlayerControlState{ enabled = false}
end

function common.enablePlayerControls()
    logger:debug("Enabling player controls")
    tes3.setPlayerControlState{ enabled = true}
end

function common.isLuaFile(file) return file:sub(-4, -1) == ".lua" end
function common.isInitFile(file) return file == "init.lua" end


local function blockActivate()
    if not tes3.player.tempData.jopBlockActivate then
        event.unregister("activate", blockActivate, { priority = 5})
        return
    end
    return true
end

function common.blockActivate()
    tes3.player.tempData.jopBlockActivate = true
    event.register("activate", blockActivate, { priority = 5})
end

function common.unblockActivate()
    tes3.player.tempData.jopBlockActivate = nil
    event.unregister("activate", blockActivate, { priority = 5})
end

---@class JOP.common.positioner.params
---@field reference tes3reference
---@field pinToWall boolean

---@param e JOP.common.positioner.params
function common.positioner(e)
    timer.delayOneFrame(function()
        if not CraftingFramework.interop.activatePositioner then
            tes3.messageBox{
                message = "Please update Crafting Framework to use this feature.",
                buttons = {"OK"}
            }
            return
        end
        CraftingFramework.interop.activatePositioner(e)
    end)
end

return common