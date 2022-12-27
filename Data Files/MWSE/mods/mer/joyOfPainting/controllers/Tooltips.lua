local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("Tooltips")
local UIHelper = require("mer.joyOfPainting.services.UIHelper")
local Painting = require("mer.joyOfPainting.items.Painting")

---@param e uiObjectTooltipEventData
local function manageTooltips(e)
    local labelText = Painting.getPaintingOrCanvasName(e.reference or e.itemData)
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