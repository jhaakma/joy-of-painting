local Shader = {}

local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("Shader")

function Shader.getShader(shaderId)
    local shader = mge.shaders.find{ name = shaderId}
    if not shader then
        shader = mgeShadersConfig.load({ name = shaderId })
    end
    return shader
end

function Shader.setEnabled(shaderId, isEnabled)
    local shader = Shader.getShader(shaderId)
    if shader then
        shader.enabled = isEnabled
    else
        logger:error("Shader %s not found", shaderId)
    end
end

function Shader.enable(shaderId)
    logger:debug("Enabling shader: %s", shaderId)
    Shader.setEnabled(shaderId, true)
end

function Shader.disable(shaderId)
    logger:debug("Disabling shader: %s", shaderId)
    Shader.setEnabled(shaderId, false)
end

function Shader.setUniform(shaderId, uniformName, value)
    local shader = Shader.getShader(shaderId)
    if shader then
        shader[uniformName] = value
    else
        logger:error("Shader %s not found", shaderId)
    end
end

return Shader

