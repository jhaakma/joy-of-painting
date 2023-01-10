local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("ActivatorController")
local Activator = require("mer.joyOfPainting.services.Activator")

---@param e activateEventData
local function onActivate(e)
    e.object = e.target.object
    e.dataHolder = e.target

    if e.activator ~= tes3.player then
        return
    end

    for _, activator in pairs(Activator.activators) do
        if activator.isActivatorItem(e) then
            if common.isShiftDown() then
                if activator.onPickup then
                    activator.onPickup(e)
                end
                return
            elseif activator.blockStackActivate and common.isStack(e.target) then
                logger:debug("%s is stack, skip", e.target.object.id)
                return
            else
                logger:debug("%s is activator item, activating", e.target.object.id)
                activator.onActivate(e)
                return true
            end
        end
    end
    logger:debug("No activators found for %s", e.target.object.id)
end
event.register("activate", onActivate)

---@param e equipEventData
local function onEquip(e)
    e.object = e.item
    e.dataHolder = e.itemData
    for _, activator in pairs(Activator.activators) do
        if activator.isActivatorItem(e) then
            activator.onActivate(e)
            return
        end
    end
end
event.register("equip", onEquip)
