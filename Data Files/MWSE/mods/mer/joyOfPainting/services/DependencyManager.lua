local DependencyManager = {}
local MWSELogger = require("logging.logger")

function DependencyManager.new(e)
    assert(type(e.modName) == "string", "modName must be a string")
    assert(type(e.dependencies) == "table", "dependencies must be a table")

    local self = {
        modName = e.modName,
        dependencies = e.dependencies,
        logger = e.logger or MWSELogger.new{
            name = string.format(e.modName),
            logLevel = e.logLevel or "INFO"
        }
    }
    return setmetatable(self, { __index = DependencyManager })
end

DependencyManager.operators = {
    [">"] = {
        major = function(major, targetMajor) return major >= targetMajor end,
        minor = function(minor, targetMinor) return minor >= targetMinor end,
        patch = function(patch, targetPatch) return patch > targetPatch end
    },
    [">="] = {
        major = function(major, targetMajor) return major >= targetMajor end,
        minor = function(minor, targetMinor) return minor >= targetMinor end,
        patch = function(patch, targetPatch) return patch >= targetPatch end
    },
    ["="] = {
        major = function(major, targetMajor) return major == targetMajor end,
        minor = function(minor, targetMinor) return minor == targetMinor end,
        patch = function(patch, targetPatch) return patch == targetPatch end
    }
}

function DependencyManager:dependencyFailMessage(dependency, currentVersion)
    timer.delayOneFrame(function()
        local message = string.format("%s requires %s to be installed.", self.modName, dependency.name)
        if dependency.version then
            message = string.format("%s requires %s %s to be installed.", self.modName, dependency.name, dependency.version)
        end
        if currentVersion then
            message = string.format("%s requires %s %s to be installed. Current version: %s", self.modName, dependency.name, dependency.version, currentVersion)
        end
        tes3ui.showMessageMenu{
            message = message,
            buttons = {
                {
                    text = "Okay",
                    callback = function()
                        tes3ui.leaveMenuMode()
                    end,
                    showRequirements = function()
                        return dependency.url == nil
                    end
                },
                {
                    text = string.format("Download %s", dependency.name),
                    callback = function()
                        os.execute("start " .. dependency.url)
                        os.exit()
                    end,
                    showRequirements = function()
                        return dependency.url ~= nil
                    end
                },
                {
                    text = "Cancel",
                    callback = function()
                        tes3ui.leaveMenuMode()
                    end,
                    showRequirements = function()
                        return dependency.url ~= nil
                    end
                }
            }
        }
    end)
end



function DependencyManager:checkDependencies()
    for _, dependency in ipairs(self.dependencies) do
        self.logger:debug("Checking dependency: %s", dependency.name)
        if dependency.luaFile then
            if include(dependency.luaFile) == nil then
                self.logger:error("Could not find dependency file: %s", dependency.luaFile)
                return self:dependencyFailMessage(dependency)
            end
        elseif dependency.versionFile then
            local path = string.format("Data Files/MWSE/mods/%s", dependency.versionFile)
            local versionFile = io.open(path, "r")
            if not versionFile then
                self.logger:error("Could not find dependency version file: %s", path)
                return self:dependencyFailMessage(dependency)
            else
                local version = ""
                for line in versionFile:lines() do -- Loops over all the lines in an open text file
                    version = line
                end
                if version == "" then
                    self.logger:error("Could not find version in dependency version file: %s", path)
                    return
                end

                local major, minor, patch = string.match(version, "(%d+)%.(%d+)%.(%d+)")
                self.logger:debug("Found version: Major: %s, Minor: %s, Patch: %s", major, minor, patch)
                local targetMajor, targetMinor, targetPatch = string.match(dependency.version, "(%d+)%.(%d+)%.(%d+)")

                local operator
                --find one of possible operators at start of string
                for operatorPattern, _ in pairs(self.operators) do
                    if string.startswith(dependency.version, operatorPattern) then
                        operator = operatorPattern
                        break
                    end
                end
                if not operator then
                    self.logger:error("Could not find operator in version string: %s", dependency.version)
                    return
                end

                self.logger:debug("Operator: %s, Target: Major: %s, Minor: %s, Patch: %s", operator, targetMajor, targetMinor, targetPatch)

                local majorCheck = self.operators[operator].major(tonumber(major), tonumber(targetMajor))
                local minorCheck = self.operators[operator].minor(tonumber(minor), tonumber(targetMinor))
                local patchCheck = self.operators[operator].patch(tonumber(patch), tonumber(targetPatch))
                if not majorCheck or not minorCheck or not patchCheck then
                    self.logger:error("Dependency version check failed")
                    return self:dependencyFailMessage(dependency, version)
                end
            end
        end
    end
    self.logger:debug("All dependencies met")
end

return DependencyManager