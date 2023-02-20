local SkillService = include("mer.joyOfPainting.services.SkillService")
local common = include("mer.joyOfPainting.common")
local config = include("mer.joyOfPainting.config")
local logger = common.createLogger("InitSkills")
--[[
    Skills
]]
local skillModule = include("OtherSkills.skillModule")

local function checkModule()
    if not skillModule then
        timer.start({
            callback = function()
                tes3.messageBox({message = "Please install Skills Module", buttons = {"Okay"} })
            end,
            type = timer.simulate,
            duration = 1.0
        })
        return false
    end

    if ( skillModule.version == nil ) or ( skillModule.version < 1.4 ) then
        timer.start({
            callback = function()
                tes3.messageBox({message = string.format("Please update Skills Module"), buttons = {"Okay"} })
            end,
            type = timer.simulate,
            duration = 1.0
        })
        return false
    end

    return true
end

--INITIALISE SKILLS--
local function onSkillsReady()
    if not checkModule() then return end
    for skill, data in pairs(config.skills) do
        data = table.deepcopy(data)
        logger:debug("Registering %s skill", skill)
        skillModule.registerSkill(data.id, data)
        SkillService.skills[skill] = skillModule.getSkill(data.id)
    end
    logger:info("JoyOfPainting skills registered")
end
event.register("OtherSkills:Ready", onSkillsReady)