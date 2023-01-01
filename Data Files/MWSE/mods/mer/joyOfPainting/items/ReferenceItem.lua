local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("artStyle")

local ReferenceItem = {}
ReferenceItem.__index = ReferenceItem

function ReferenceItem:new(e)
    assert(e.reference or e.item, "ReferenceItem requires either a reference or an item")
    local referenceItem = setmetatable({}, self)
    referenceItem.reference = e.reference
    referenceItem.item = e.item
    if e.reference and not e.item then
        referenceItem.item = e.reference.object
    end
    referenceItem.dataHolder = (e.itemData ~= nil) and e.itemData or e.reference
    referenceItem.data = setmetatable({}, {
        __index = function(t, k)
            if not (
                referenceItem.dataHolder
                and referenceItem.dataHolder.data
                and referenceItem.dataHolder.data
            ) then
                return nil
            end
            return referenceItem.dataHolder.data[k]
        end,
        __newindex = function(t, k, v)
            if not (
                referenceItem.dataHolder
                and referenceItem.dataHolder.data
                and referenceItem.dataHolder.data
            ) then
                if not referenceItem.reference then
                    logger:debug("referenceItem.item: %s", referenceItem.item)
                    --create itemData
                    referenceItem.dataholder = tes3.addItemData{
                        to = tes3.player,
                        item = referenceItem.item,
                    }
                    if not referenceItem.dataHolder then
                        logger:error("Failed to create itemData for referenceItem")
                        return
                    end
                end
            end
            referenceItem.dataHolder.data[k] = v
        end
    })
end

return ReferenceItem