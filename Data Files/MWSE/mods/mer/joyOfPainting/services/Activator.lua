local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Activator")
local ReferenceManager = require("mer.joyOfPainting.services.ReferenceManager")

local ANIM_TIMER_EVENT = "JOP:Activator:playAnimation:timer"

local Activator = {
    ---@type JoyOfPainting.Activator[]
    activators = {}
}

---@class JoyOfPainting.Activator.callbackParams
---@field target tes3reference?
---@field item tes3item?
---@field itemData tes3itemData?

---@class JoyOfPainting.Activator
---@field id string
---@field onActivate function
---@field onPickup function
---@field isActivatorItem function
---@field blockStackActivate boolean
---@field getAnimationGroup fun(reference:tes3reference):number? Returns the current active animation group to play


---@param activator JoyOfPainting.Activator
function Activator.registerActivator(activator)
    logger:assert(type(activator.onActivate) == "function", "onActivate must be a function")
    logger:assert(type(activator.isActivatorItem) == "function", "isActivatorItem must be a function")
    table.insert(Activator.activators, activator)
end

---@param e activateEventData
function Activator.doBlockActivate(e)
    if e.activator ~= tes3.player then
        logger:debug("Not player, skip")
        return true
    end

    return false
end

local function animationCallback(e)
    local reference, nextAnimation = unpack(e.timer.data)
    logger:debug("Animation callback")
    if e.nextAnimation then
        logger:debug("Playing next animation %s", nextAnimation)
        tes3.playAnimation{
            reference = reference,
            group = nextAnimation,
            startFlag = tes3.animationStartFlag.normal,
            loopCount = 0,
        }
    end
    logger:debug("Unblocking activate")
    common.unblockActivate()
end
timer.register(ANIM_TIMER_EVENT, animationCallback)

---@class JOP.Activator.playAnimation.params
---@field reference tes3reference? Reference to play the animation on
---@field group table? Animation group to play
---@field sound string? Sound to play
---@field duration number? Duration of the animation
---@field callback function? Called after the animation is done
---@field nextAnimation number? The animation to play if this one is interrupted by save/load

---@param e JOP.Activator.playAnimation.params
function Activator.playActivatorAnimation(e)

    logger:debug("Playing animation %s for %s", e.group.group, e.reference)
    --play animation
    tes3.playAnimation{
        reference = e.reference,
        group = e.group.group,
        startFlag = tes3.animationStartFlag.immediate,
        loopCount = 0,
    }
    if e.sound then
        tes3.playSound{
            reference = e.reference,
            sound = e.sound,
        }
    end
    if e.group.duration then
        common.blockActivate()
        --persistent timer to play the next animation
        timer.start{
            duration = e.group.duration,
            type = timer.simulate,
            callback = ANIM_TIMER_EVENT,
            data = { e.reference, e.nextAnimation},
            persist = true,
        }
        --non persistent timer to do custom calback
        timer.start{
            duration = e.group.duration,
            type = timer.real,
            callback = function()
                logger:debug("Animation timer callback")
                if e.callback then
                    logger:debug("Calling callback")
                    e.callback()
                end
            end,
        }
    end
end

return Activator