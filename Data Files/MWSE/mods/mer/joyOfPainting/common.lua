local common = {}

local config = require("mer.joyOfPainting.config")

local MWSELogger = require("logging.logger")
local CraftingFramework = require("CraftingFramework")

---@type table<string, mwseLogger>
common.loggers = {}

function common.createLogger(serviceName)
    local logger = MWSELogger.new{
        name = string.format("JoyOfPainting - %s", serviceName),
        logLevel = config.mcm.logLevel,
        includeTimestamp = true,
    }
    common.loggers[serviceName] = logger
    return logger
end
local logger = common.createLogger("common")

function common.getVersion()
    return config.metadata.package.version
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

---@param e CraftingFramework.interop.activatePositionerParams
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

function common.getCanvasTexture(texture)
    if (lfs.fileexists(tes3.installDirectory .. "\\Data Files\\Textures\\" .. texture)) then
        return "Data Files\\Textures\\" .. texture
    else
        return "Data Files\\Textures\\jop\\" .. texture
    end
end

return common