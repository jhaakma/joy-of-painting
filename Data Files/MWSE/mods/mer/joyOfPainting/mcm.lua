local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")

local LINKS_LIST = {
    {
        text = "Release history",
        url = "https://github.com/jhaakma/joy-of-painting/releases"
    },
    -- {
    --     text = "Wiki",
    --     url = "https://github.com/jhaakma/joy-of-painting/wiki"
    -- },
    -- {
    --     text = "Nexus",
    --     url = "https://www.nexusmods.com/morrowind/mods/51366"
    -- },
    -- {
    --     text = "Buy me a coffee",
    --     url = "https://ko-fi.com/merlord"
    -- },
}
local CREDITS_LIST = {
    {
        text = "Made by Merlord",
        url = "https://www.nexusmods.com/users/3040468?tab=user+files",
    },
}

local function addSideBar(component)
    component.sidebar:createCategory(config.modName)
    component.sidebar:createInfo{ text = config.modDescription }

    local linksCategory = component.sidebar:createCategory("Links")
    for _, link in ipairs(LINKS_LIST) do
        linksCategory:createHyperLink{ text = link.text, url = link.url }
    end
    local creditsCategory = component.sidebar:createCategory("Credits")
    for _, credit in ipairs(CREDITS_LIST) do
        creditsCategory:createHyperLink{ text = credit.text, url = credit.url }
    end
end

local function registerMCM()
    local template = mwse.mcm.createTemplate{ name = config.modName }
    template:saveOnClose(config.configPath, config.mcm)
    template:register()

    local page = template:createSideBarPage{ label = "Settings"}
    addSideBar(page)

    page:createYesNoButton{
        label = "Enable Mod",
        description = "Turn this mod on or off. Expect a delay if enabling for the first time this game session, as it will take a moment to register all of the recipes.",
        variable = mwse.mcm.createTableVariable{ id = "enabled", table = config.mcm },
        callback = function(self)
            if self.variable.value == true then
                event.trigger("ItemBrowser:RegisterMenus")
            end
        end
    }

    page:createSlider{
        label = "Max Saved Paintings",
        description = "Set the maximum number of full-resolution paintings of each art style saved to `Data Files/Textures/jop/saved/`. Once the maximum is reached, the oldest painting will be deleted to make room for the new one.",
        min = 1,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{ id = "maxSavedPaintings", table = config.mcm },
    }

    page:createTextField{
        label = "Saved Painting Size",
        description = "Set the size of the saved paintings. This will be the length of the smallest dimension of the painting.",
        variable = mwse.mcm.createTableVariable{ id = "savedPaintingSize", table = config.mcm },
        numbersOnly = true,
    }

    page:createYesNoButton{
        label = "Enable Tapestry Removal",
        description = "When enabled, you can activate a tapestry to remove it to make room for a painting.",
        variable = mwse.mcm.createTableVariable{ id = "enableTapestryRemoval", table = config.mcm },
    }

    page:createDropdown{
        label = "Log Level",
        description = "Set the logging level for all JoyOfPainting Loggers.",
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable =  mwse.mcm.createTableVariable{ id = "logLevel", table = config.mcm},
        callback = function(self)
            for _, logger in pairs(common.loggers) do
                logger:setLogLevel(self.variable.value)
            end
        end
    }

end
event.register("modConfigReady", registerMCM)