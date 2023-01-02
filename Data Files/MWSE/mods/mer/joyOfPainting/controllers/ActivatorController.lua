local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("ActivatorController")
local Activator = require("mer.joyOfPainting.services.Activator")

---@param e activateEventData
local function onActivate(e)
    e.object = e.target.object
    e.dataHlder = e.target
    for _, activator in pairs(Activator.activators) do
        if Activator.doBlockActivate(e) then return end
        if activator.blockStackActivate and common.isStack(e.target) then
            logger:debug("%s is stack, skip", e.target.object.id)
            return
        end
        if activator.isActivatorItem(e) then
            activator.onActivate(e)
            return true
        end
    end
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
