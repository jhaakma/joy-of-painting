local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("Interop")
local Interop = {}
Interop.ArtStyle = require("mer.joyOfPainting.items.ArtStyle")
Interop.Brush = require("mer.joyOfPainting.items.Brush")
Interop.Easel = require("mer.joyOfPainting.items.Easel")
Interop.Frame = require("mer.joyOfPainting.items.Frame")
Interop.Palette = require("mer.joyOfPainting.items.Palette")
Interop.Painting = require("mer.joyOfPainting.items.Painting")
Interop.Sketchbook = require("mer.joyOfPainting.items.Sketchbook")
Interop.Refill = require("mer.joyOfPainting.items.Refill")
Interop.Tapestry = require("mer.joyOfPainting.items.Tapestry")
Interop.Subject = require("mer.joyOfPainting.items.Subject")

--Helper/Dialog functions
---

---@class JOP.Interop.paintingFilter
---@field objectId string? If provided, checks for a painting with a subject with the specified objectId
---@field subjectIds string[]? If provided, checks for a painting with the specified subjectIds
---@field artStyle string? If provided, only checks for paintings with the specified artStyle
---@field canvasType "paper"|"canvas" If provided, only checks for paintings with the specified canvasType
---@field reference tes3reference? (Default: tes3.player) The reference to check for a painting


---Check if the itemData is a painting
---@param item tes3item
---@param itemData tes3itemData
---@param e JOP.Interop.paintingFilter
local function isPainting(item, itemData, e)
    local dataIsPainting =  Interop.Painting.itemDataIsPainting(itemData)
    if not dataIsPainting then return false end
    local painting = Interop.Painting:new{
        item = item,
        itemData = itemData
    }

    local subjectResults = painting:getSubjectResults()

    --Check objectId
    if e.objectId then
        if subjectResults[e.objectId] == nil then
            return false
        end
    end

    --Check subjectIds
    if e.subjectIds then
        logger:debug("Checking subjectIds")

        for _, subjectId in ipairs(e.subjectIds) do
            logger:debug("Checking subjectId: %s", subjectId)
            if table.size(subjectResults) == 0 then
                logger:debug("No subject results")
                return false
            end
            local found = false
            for _, result in pairs(subjectResults) do
                logger:debug("- checking against result %s", result.objectId)
                if result.subjectIds then
                    if result.subjectIds[subjectId:lower()] then
                        logger:debug("SubjectId found %s", subjectId)
                        found = true
                    end
                end
            end
            if not found then
                logger:debug("SubjectId not found")
                return false
            end
        end
    end

    --Check artStyle
    if e.artStyle then
        if painting.data.artStyle ~= e.artStyle then
            return false
        end
    end

    --Check canvasType
    if e.canvasType then
        if e.canvasType ~= painting:getCanvasType() then
            return false
        end
    end

    return true
end


---Get a painting from the player's inventory
---@param e JOP.Interop.paintingFilter | string # If a string is provided, it is treated as the objectId
---@return JOP.Painting?
function Interop.getPainting(e)
    e = e or {}
    if type(e) == "string" then
        e = { objectId = e }
    end

    local ref = e.reference or tes3.player
    for _, stack in pairs(ref.object.inventory) do
        if stack.variables then
            for _, itemData in ipairs(stack.variables) do
                if isPainting(stack.object, itemData, e) then
                    return Interop.Painting:new{
                        item = stack.object,
                        itemData = itemData
                    }
                end
            end
        end
    end
    logger:debug("No painting found")
    return nil
end

---Check if the player has a painting in their inventory
---@param e JOP.Interop.paintingFilter | string # If a string is provided, it is treated as the subjectId
---@return boolean
function Interop.hasPainting(e)
    local painting = Interop.getPainting(e)
    return painting ~= nil
end

return Interop
