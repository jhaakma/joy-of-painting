local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("Tooltips")
local UIHelper = require("mer.joyOfPainting.services.UIHelper")
local Easel = require("mer.joyOfPainting.items.Easel")

---@param e uiObjectTooltipEventData
local function manageTooltips(e)
    local easel = e.reference and Easel:new(e.reference)
    if easel then
        local labelText = easel:getPaintingOrCanvasName()
        logger:trace("Adding '%s' for %s",
            labelText, easel.reference.object.id)
        UIHelper.addLabelToTooltip{
            tooltip = e.tooltip,
            labelText = labelText,
            color = tes3ui.getPalette("normal_color")
        }
    end
end
event.register(tes3.event.uiObjectTooltip, manageTooltips)