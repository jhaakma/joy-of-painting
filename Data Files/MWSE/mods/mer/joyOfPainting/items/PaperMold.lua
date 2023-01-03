local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("PaperMold")
local NodeManager = require("mer.joyOfPainting.services.NodeManager")

---@class JOP.PaperMold
local PaperMold = {
    data = nil,
    dataHolder = nil,
    item = nil,
    itemData = nil,
    reference = nil,
}
PaperMold.__index = PaperMold

function PaperMold.registerPaperMold(e)
    common.logAssert(logger, type(e.id) == "string", "id must be a string")
    logger:debug("Registering paper mold %s", e.id)
    e.id = e.id:lower()
    config.paperMolds[e.id] = table.copy(e, {})
end

function PaperMold.registerPaperPulp(e)
    common.logAssert(logger, type(e.id) == "string", "id must be a string")
    logger:debug("Registering paper pulp %s", e.id)
    e.id = e.id:lower()
    config.paperPulps[e.id] = table.copy(e, {})
end

---@return JOP.PaperMold|nil
function PaperMold:new(e)
    common.logAssert(logger, e.reference or e.item, "PaperMold requires either a reference or an item")
    local paperMold = setmetatable({}, self)

    paperMold.reference = e.reference
    paperMold.item = e.item
    paperMold.itemData = e.itemData
    if e.reference and not e.item then
        paperMold.item = e.reference.object --[[@as JOP.tes3itemChildren]]
    end

    if config.paperMolds[paperMold.item.id:lower()] == nil then
        logger:debug("%s is not a paper mold", paperMold.item.id)
        return nil
    end

    paperMold.dataHolder = (e.itemData ~= nil) and e.itemData or e.reference
    paperMold.data = setmetatable({}, {
        __index = function(_, k)
            if not (
                paperMold.dataHolder
                and paperMold.dataHolder.data
                and paperMold.dataHolder.data.joyOfPainting
            ) then
                return nil
            end
            return paperMold.dataHolder.data.joyOfPainting[k]
        end,
        __newindex = function(_, k, v)
            if paperMold.dataHolder == nil then
                logger:debug("Setting value %s and dataHolder doesn't exist yet", k)
                if not paperMold.reference then
                    logger:debug("paperMold.item: %s", paperMold.item)
                    --create itemData
                    paperMold.dataHolder = tes3.addItemData{
                        to = tes3.player,
                        item = paperMold.item.id,
                    }
                    if paperMold.dataHolder == nil then
                        logger:error("Failed to create itemData for paperMold")
                        return
                    end
                end
            end
            if not ( paperMold.dataHolder.data and paperMold.dataHolder.data.joyOfPainting) then
                paperMold.dataHolder.data.joyOfPainting = {}
            end
            paperMold.dataHolder.data.joyOfPainting[k] = v
        end
    })
    return paperMold
end

function PaperMold:hasPulp()
    return self.data.timeAddedPulp ~= nil
end

function PaperMold:hasPaper()
    return self.data.hasPaper
end

function PaperMold:playerHasPulp()
    for id, _ in pairs(config.paperPulps) do
        if tes3.player.object.inventory:contains(id) then
            return true
        end
    end
    return false
end

function PaperMold:getHoursToDry()
    local moldData = config.paperMolds[self.item.id:lower()]
    if moldData == nil then
        logger:warn("Paper mold %s not registered", self.item.id)
        return 0
    end
    return moldData.hoursToDry
end

function PaperMold:getTimeAddedPulp()
    return self.data.timeAddedPulp
end

function PaperMold:doAddPulp()
    if not self:playerHasPulp() then
        logger:warn("Player doesn't have pulp")
        return
    end

    if self:hasPulp() then
        logger:warn("Paper mold already has pulp")
        return
    end

    --remove pulp from player inventory
    for id, _ in pairs(config.paperPulps) do
        if tes3.player.object.inventory:contains(id) then
            tes3.removeItem{
                reference = tes3.player,
                item = id,
            }
            break
        end
    end
    self.data.timeAddedPulp = tes3.getSimulationTimestamp()
    NodeManager.updateSwitch("paper_mold")
end

function PaperMold:processMold(timestamp)
    local now = timestamp or tes3.getSimulationTimestamp()
    if self:hasPulp() then
        if now - self:getTimeAddedPulp() > self:getHoursToDry() then
            self:dryPaper()
        end
    end
end

function PaperMold:dryPaper()
    self.data.hasPaper = true
    self.data.timeAddedPulp = nil
    NodeManager.updateSwitch("paper_mold")
end

function PaperMold:takePaper()
    if not self:hasPaper() then
        logger:warn("Paper mold doesn't have paper")
        return
    end
    local paperConfig = config.paperMolds[self.item.id:lower()]
    local paperId = paperConfig.paperId
    if paperId == nil then
        logger:warn("Paper mold %s doesn't have a paperId", self.item.id)
        return
    end
    tes3.addItem{
        reference = tes3.player,
        item = paperId,
        count = paperConfig.paperPerPulp
    }
    self.data.hasPaper = false
    NodeManager.updateSwitch("paper_mold")
end


return PaperMold
