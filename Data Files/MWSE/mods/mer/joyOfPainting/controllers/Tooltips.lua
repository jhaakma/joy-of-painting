local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("Tooltips")
local UIHelper = require("mer.joyOfPainting.services.UIHelper")
local Painting = require("mer.joyOfPainting.items.Painting")

---@param e uiObjectTooltipEventData
local function manageTooltips(e)
    local painting = Painting:new{
        reference = e.reference,
        item = e.object --[[@as JOP.tes3itemChildren]],
        itemData = e.itemData
    }
    if not painting:hasCanvasData() then return end
    local labelText
    if painting.data.paintingName then
        local paintingName = painting.data.paintingName
        labelText = string.format('"%s"', paintingName)
    elseif painting.data.canvasId then
        labelText = tes3.getObject(painting.data.canvasId).name
    end
    if labelText then
        UIHelper.addLabelToTooltip{
            tooltip = e.tooltip,
            labelText = labelText,
            color = tes3ui.getPalette("normal_color")
        }
    else
        logger:trace("No painting or canvas data found")
    end
end
event.register(tes3.event.uiObjectTooltip, manageTooltips)