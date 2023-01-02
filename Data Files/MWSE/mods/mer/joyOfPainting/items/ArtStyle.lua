local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("ArtStyle")


local Paint = require("mer.joyOfPainting.items.Paint")

---@class JOP.ArtStyle
---@field name string The name of the art style
---@field magickCommand function A function that returns a Magick command to execute
---@field shaders string[] A list of shaders to apply to the painting
---@field controls string[] A list of controls to use for this art style
---@field valueModifier number The value modifier for the painting
---@field animAlphaTexture string The texture used to control the alpha during painting animation
---@field requiresEasel boolean? Whether the art style requires an easel to be painted on
---@field paintType JOP.PaintType? The brush type to use for this art style
---@field brushType JOP.BrushType? The brush type to use for this art style
local ArtStyle = {}
ArtStyle.__index = ArtStyle

---@param data JOP.ArtStyle.data
function ArtStyle:new(data)
    local artStyle = setmetatable(table.copy(data), self)
    artStyle.paintType = config.paintTypes[data.paintType]
    if artStyle.paintType.brushType then
        artStyle.brushType = config.brushTypes[artStyle.paintType.brushType]
    end
    return artStyle
end

function ArtStyle:isValidBrush(id)
    local brushData = config.brushes[id:lower()]
    if brushData then
       return brushData.brushType == self.brushType.id:lower()
    end
end

---@return table<string, JOP.Brush>
function ArtStyle:getBrushes()
    --iterate config.brushes and return those where this brush type is in its brushTypes list
    local brushes = {}
    for brushId, brushData in pairs(config.brushes) do
        if self:isValidBrush(brushId) then
            brushes[brushId] = brushData
        end
    end
    return brushes
end




function ArtStyle:playerHasBrush()
    logger:debug("Checking for %s brush", self.name)

    if not self.brushType then
        logger:debug("No brush required for this art style")
        return true
    end

    for _, brush in pairs(self:getBrushes()) do
        if tes3.player.object.inventory:contains(brush.id) then
            logger:debug("Found brush: %s", brush)
            return true
        end
    end
    --search area
    for _, cell in pairs(tes3.getActiveCells()) do
        for reference in cell:iterateReferences() do
            if self:getPaints()[reference.object.id:lower()] and not common.isStack(reference) then
                if reference.position:distance(tes3.player.position) < tes3.getPlayerActivationDistance() then
                    logger:debug("Found nearby brush reference: %s", reference.object.id)
                    return true
                end
            end
        end
    end

    return false
end

function ArtStyle:isValidPaint(id)
    local paintData = config.paintItems[id:lower()]
    if paintData then
        return paintData.paintTypes[self.paintType.id] ~= nil
    end
end

---@return table<string, JOP.Paint>
function ArtStyle:getPaints()
    local paints = {}
    for paintId, paintData in pairs(config.paintItems) do
        if self:isValidPaint(paintId) then
            paints[paintId] = paintData
        end
    end
    return paints
end

function ArtStyle:playerHasPaint()
    logger:debug("Checking playerHasPaint for %s", self.name)
    if not self.paintType then
        logger:debug("No paint required for this art style")
        return true
    end
    --Search inventory
    for paintId, paintData in pairs(self:getPaints()) do
        logger:debug("Checking paint: %s", paintId)
        local itemStack = tes3.player.object.inventory:findItemStack(paintId)
        if itemStack then
            logger:debug("Found paint: %s", paintId)
            --if no variables, then treat it as full
            if not itemStack.variables then
                logger:debug("No variables, treating as full")
                return true
            end

            if itemStack.count > #itemStack.variables then
                logger:debug("stack count greater than variabels, has at least one full")
                return true
            end

            for _, itemData in ipairs(itemStack.variables) do
                local paint = Paint:new{
                    item = itemStack.object,
                    itemData = itemData
                }
                if paint.data.uses > 0 then
                    logger:debug("%d uses remaining", paint.data.uses)
                    return true
                end
            end
        end
    end
    --Search nearby area
    for _, cell in pairs(tes3.getActiveCells()) do
        for reference in cell:iterateReferences() do
            if self:isValidPaint(reference.object.id) and not common.isStack(reference) then
                if common.closeEnough(reference) then
                    local paint = Paint:new({
                        reference = reference
                    })
                    if paint.data.uses > 0 then
                        logger:debug("Found nearby paint reference: %s", reference.object.id)
                        return true
                    end
                end
            end
        end
    end
    return false
end


function ArtStyle:usePaint()
    logger:debug("Using up paint for %s", self.name)
    ---@type JOP.Paint.params[]
    local usedStacks = {}
    ---@type JOP.Paint.params[]
    local newStacks = {}

    for paintId, paintData in pairs(self:getPaints()) do
        local itemStack = tes3.player.object.inventory:findItemStack(paintId)
        if itemStack then
            if itemStack.variables then
                for _, itemData in ipairs(itemStack.variables) do
                    if itemData.data.joyOfPainting then
                        table.insert(usedStacks, {
                            paintData = paintData,
                            item = itemStack.object,
                            itemData = itemData
                        })
                    else
                        table.insert(newStacks, {
                            paintData = paintData,
                            item = itemStack.object,
                            itemData = itemData
                        })
                    end
                end
            else
                table.insert(newStacks, {
                    paintData = paintData,
                    item = itemStack.object
                })
            end
        end
    end
    --prioritise used stacks
    for _, stackData in ipairs(usedStacks) do
        local paint = Paint:new(stackData)
        if paint:use() then
            return
        end
    end
    --then new stacks
    for _, stackData in ipairs(newStacks) do
        local paint = Paint:new(stackData)
        logger:debug("new stack: %s", json.encode(stackData, {indent = true}))
        if paint:use() then
            return
        end
    end
    --then nearby reference
    for _, cell in pairs(tes3.getActiveCells()) do
        for reference in cell:iterateReferences() do
            if self:isValidPaint(reference.object.id) and not common.isStack(reference) then
                if common.closeEnough(reference) then
                    logger:debug("Found nearby paint reference: %s", reference.object.id)
                    local paint = Paint:new({
                        item = reference.object,
                        reference = reference
                    })

                    if paint:use() then
                        return
                    end
                end
            end
        end
    end

    logger:warn("No paint found to use")
end

function ArtStyle:getButton(callback)
    return {
        text = self.name,
        callback = callback,
        enableRequirements = function()
            return self:playerHasBrush() and self:playerHasPaint()
        end,
        tooltipDisabled = function()
            local text
            local hasBrush = self:playerHasBrush()
            local hasPaint = self:playerHasPaint()
            if not hasBrush and not hasPaint then
                text = string.format("Requires %s and %s", self.brushType.name, self.paintType.name)
            elseif not hasBrush then
                text = string.format("Requires %s", self.brushType.name)
            elseif not hasPaint then
                text = string.format("Requires %s", self.paintType.name)
            end
            return { text = text }
        end
    }
end

return ArtStyle