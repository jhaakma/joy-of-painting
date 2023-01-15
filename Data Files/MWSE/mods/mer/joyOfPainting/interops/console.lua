local SkillService = require("mer.joyOfPainting.services.SkillService")
event.register("UIEXP:sandboxConsole", function(e)
    e.sandbox.jop = {
        skills = SkillService.skills
    }
    e.sandbox.coc = function(cellName)
        local cell = tes3.getCell({ id = cellName })
        if cell.isInterior then
            tes3.positionCell({
                cell = cell,
                position = {x = 0, y = 0, z = 0},
                reference = tes3.player
            })
        end
    end
end)