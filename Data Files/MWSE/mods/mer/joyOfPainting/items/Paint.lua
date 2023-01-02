local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Paint")
---@class JOP.Paint
local Paint = {
    ---@type JOP.Paint.PaintData
    paintData = nil,
    ---@type tes3reference
    reference = nil,
    item = nil,
    itemData = nil,
    dataHolder = nil,
    data = nil,
}
Paint.__index = Paint

---@class JOP.Paint.params
---@field reference tes3reference?
---@field item tes3item?
---@field itemData tes3itemData?
---@field paintData JOP.Paint.PaintData

---@param e JOP.Paint.params
---@return JOP.Paint
function Paint:new(e)
    assert(e.reference or e.item, "Paint requires either a reference or an item")
    local paint = setmetatable({}, self)

    paint.reference = e.reference
    paint.item = e.item
    self.itemData = e.itemData
    if e.reference and not e.item then
        paint.item = e.reference.object --[[@as JOP.tes3itemChildren]]
    end

    paint.paintData = config.paintItems[paint.item.id:lower()]
    paint.dataHolder = (e.itemData ~= nil) and e.itemData or e.reference
    paint.data = setmetatable({}, {
        __index = function(_, k)
            if not (
                paint.dataHolder
                and paint.dataHolder.data
                and paint.dataHolder.data.joyOfPainting
            ) then
                if k == "uses" then
                    return paint.paintData.uses
                end
                return nil
            end
            return paint.dataHolder.data.joyOfPainting[k]
        end,
        __newindex = function(_, k, v)
            if paint.dataHolder == nil then
                logger:debug("Setting value %s and dataHolder doesn't exist yet", k)
                if not paint.reference then
                    logger:debug("paint.item: %s", paint.item)
                    --create itemData
                    paint.dataHolder = tes3.addItemData{
                        to = tes3.player,
                        item = paint.item.id,
                    }
                    if paint.dataHolder == nil then
                        logger:error("Failed to create itemData for paint")
                        return
                    end
                end
            end
            if not ( paint.dataHolder.data and paint.dataHolder.data.joyOfPainting) then
                paint.dataHolder.data.joyOfPainting = {}
            end
            paint.dataHolder.data.joyOfPainting[k] = v
        end
    })
    return paint
end

function Paint:use()
    if self.data.uses > 0 then
        logger:debug("Using up paint for %s", self.item.id)
        self.data.uses = self.data.uses - 1
        if self.paintData.breaks and self.data.uses == 0 then
            logger:debug("Paint has no more uses, removing from inventory")
            if self.reference then
                self.reference:delete()
            else
                tes3.removeItem{
                    reference = tes3.player,
                    item = self.item,
                    itemData = self.itemData,
                    playSound = false,
                }
            end
        end
        return true
    end
    logger:debug("Paint has no more uses")
    return false
end

function Paint:getRemainingUses()
    if not self.data.uses then
        return self.paintData.uses
    end
    return self.data.uses
end

function Paint:getMaxUses()
    return self.paintData.uses
end

function Paint.isPaint(id)
    return config.paintItems[id:lower()] ~= nil
end

return Paint