local Subject = require("mer.joyOfPainting.items.Subject")

---@type JOP.Subject.registerSubjectParams[]
local subjects = {
    {
        id = "fargoth",
        objectIds = {"fargoth"},
    },
    {
        id = "npc",
        requirements = function(e)
            return e.reference.baseObject.objectType == tes3.objectType.npc
        end
    },
    {
        id = "creature",
        requirements = function(e)
            return e.reference.baseObject.objectType == tes3.objectType.creature
        end
    },
    {
        id = "lighthouse",
        name = "Lighthouse",
        objectIds = {"ex_common_lighthouse"},
    },
    {
        id = "a_siltstrider",
        objectIds = {"a_siltstrider"},
    }
}

for _, subject in ipairs(subjects) do
    Subject.registerSubject(subject)
end