--[[
    Service for taking a photo. Includes toggling shaders,
    adjusting Zoom etc
]]

local ImageBuilder = require("mer.joyOfPainting.services.ImageBuilder")
local Shader = require("mer.joyOfPainting.services.Shader")
local config = require("mer.joyOfPainting.config")
local common = require("mer.joyOfPainting.common")
local logger = common.createLogger("PhotoMenu")
local GUID = require("mer.joyOfPainting.services.GUID")
local UIHelper = require("mer.joyOfPainting.services.UIHelper")
local SkillService = require("mer.joyOfPainting.services.SkillService")
local PaintService = require("mer.joyOfPainting.services.PaintService")

local alwaysOnShaders = {
    config.shaders.window,
}

---@class JOP.PhotoMenu
local PhotoMenu = {
    shaders = nil,
    ---@type JOP.ArtStyle
    artStyle = nil,
    canvasConfig = nil,
    paintingName = nil,
    captureCallback = nil,
    closeCallback = nil,
    cancelCallback = nil,
    finalCallback = nil,
    isLooking = false
}
PhotoMenu.menuID = "TJOP.PhotoMenu"

local function getpaintingTexture()
    return GUID.generate() .. ".dds"
end

function PhotoMenu:new(data)
    logger:debug("Creating new PhotoMenu")
    local o = setmetatable(data, self)
    self.__index = self
    o.shaders = {}
    --add always on shaders
    for _, shader in ipairs(alwaysOnShaders) do
        table.insert(o.shaders, shader)
    end
    if data.artStyle and data.artStyle.shaders then
        logger:debug("artstyle has shaders")
        for _, shader in ipairs(data.artStyle.shaders) do
            table.insert(o.shaders, shader)
        end
    end

    return o
end

--[[
    Captures the current scene and saves it to a painting
]]
function PhotoMenu:capture()
    logger:debug("Capturing image")
    local paintingTexture = getpaintingTexture()
    logger:debug("Painting name: %s", paintingTexture)

    local imageData = {
        savedPaintingPath = "Data Files\\" .. PaintService.getSavedPaintingPath(),
        paintingPath = "Data Files\\" .. PaintService.getPaintingTexturePath(paintingTexture),
        canvasConfig = self.canvasConfig,
        iconSize = 32,
        iconBorder = 3,
        iconPath = config.locations.paintingIconsDir .. paintingTexture,
        framedIconPath = config.locations.paintingIconsDir .. "f_" .. paintingTexture,
        framePath = config.locations.frameIconsDir .. "frame_square.dds",
    }
    local builder = ImageBuilder:new(imageData)
        :registerStep("doCaptureCallback", function(next)
            if self.captureCallback then
                logger:debug("Calling capture callback")
                self.captureCallback({
                    paintingTexture = paintingTexture,
                })
            end
        end)
        :registerStep("startPainting", function()
            logger:debug("Starting painting")
            self:hideMenu()
            self:finishMenu()
            tes3.playSound{sound = self.canvasConfig.animSound}
        end)
        :registerStep("waitForPaintingAnim", function(next)
            logger:debug("Waiting %G seconds for painting animation to finish",
                self.canvasConfig.animSpeed)
            timer.start{
                duration = self.canvasConfig.animSpeed,
                type = timer.simulate,
                callback = next
            }
            return true
        end)
        :registerStep("enableControls", function()
            logger:debug("Enabling controls")
            self:enablePlayerControls()
        end)
        :registerStep("progressSkill", function()
            SkillService.progressSkillFromPainting()
        end)
        :registerStep("namePainting", function(next)
            self.paintingName = "Untitled"
            UIHelper.openPaintingMenu{
                dataHolder = self,
                paintingTexture = paintingTexture,
                canvasId = self.canvasConfig.canvasId,
                callback = next,
                cancelCallback = self.cancelCallback,
                setNameText = "Name " .. self.artStyle.name,
            }
            return true
        end)
        :registerStep("doFinalCallback", function()
            if self.finalCallback then
                logger:debug("Calling finalCallback")
                if self.paintingName == nil or self.paintingName == "" then
                    self.paintingName = "Untitled"
                end
                self.finalCallback{
                    paintingName = self.paintingName
                }
                logger:debug("Successfully captured painting.")
            end
        end)
        :registerArtStyle(self.artStyle)

    builder:start()
        :takeScreenshot()
        [self.artStyle.name](builder)
        :incrementSavedPaintingIndex()
        :createPaintingTexture()
        :createIcon()
        :deleteScreenshot()
        :calculateAverageColor()
        :startPainting()
        :finish()
        :doCaptureCallback()
        :waitForPaintingAnim()
        :enableControls()
        :namePainting()
        :progressSkill()
        :doFinalCallback()
        :build()
end


function PhotoMenu:createCaptureButtons(parent)
    logger:debug("Creating capture button")
    local paintButton = parent:createButton {
        id = "JOP.CaptureButton",
        text = "Paint"
    }
    paintButton:register("mouseClick", function(e)
        self:capture()
    end)
end

function PhotoMenu:createHeader(parent)
    logger:debug("Creating header")
    parent:createLabel {
        id = "JOP.Header",
        text = "Hold Right Click to hide menu and move camera"
    }
end

function PhotoMenu:createZoomSlider(parent)
    logger:debug("Creating zoom slider")
    config.persistent.zoom = config.persistent.zoom or 100
    self.slider = mwse.mcm.createSlider(parent, {
        label = "Zoom: %s%%",
        current = config.persistent.zoom,
        min = 100,
        max = 1000,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable {
            id = "zoom",
            table = config.persistent
        }
    })
    self.slider.callback = function()
        logger:debug("Setting Zoom to %s", config.persistent.zoom)
        mge.camera.zoom = config.persistent.zoom / 100
    end
end

local lightingModeCycle = {
    [mge.lightingMode.perPixel] = mge.lightingMode.vertex,
    [mge.lightingMode.vertex] = mge.lightingMode.perPixel,
}
local lightingModeText = {
    [mge.lightingMode.perPixel] = "Per Pixel",
    [mge.lightingMode.vertex] = "Vertex",
}

function PhotoMenu:createLightingModeButton(parent)
    logger:debug("Creating lighting mode button")
    config.persistent.lightingMode = mge.getLightingMode()
    local button = parent:createButton {
        id = "JOP.LightingModeButton",
        text = "Lighting Mode: " .. lightingModeText[config.persistent.lightingMode]
    }
    button:register("mouseClick", function(e)
        config.persistent.lightingMode = lightingModeCycle[config.persistent.lightingMode]
        mge.setLightingMode(config.persistent.lightingMode)
        button.text = "Lighting Mode: " .. lightingModeText[config.persistent.lightingMode]
    end)
end

function PhotoMenu:setVignette()
    local vignetteShader = config.shaders.vignette
    if self.vignette then
        Shader.enable(vignetteShader)
        table.insert(self.shaders, vignetteShader)
    else
        Shader.disable(vignetteShader)
        local vignetteIndex = table.find(self.shaders, vignetteShader)
        if vignetteIndex then
            table.remove(self.shaders, vignetteIndex)
        end
    end
end

function PhotoMenu:createVignetteToggleButton(parent)
    logger:debug("Creating Vignette button")
    local button = parent:createButton {
        id = "JOP.VignetteButton",
        text = "Vignette: " .. (self.vignette and "On" or "Off")
    }

    button:register("mouseClick", function(e)
        self.vignette = not self.vignette
        self:setVignette()
        button.text = "Vignette: " .. (self.vignette and "On" or "Off")
    end)
end

function PhotoMenu:setShaderValue(control)
    local shaderValue = math.remap(config.persistent[control.id], 0, 100, control.shaderMin, control.shaderMax)
    logger:debug("Setting %s to %s", control.id, shaderValue)
    Shader.setUniform(control.shader, control.uniform, shaderValue)
end

---@param parent any
---@param control JOP.ArtStyle.control
function PhotoMenu:createControlSlider(parent, control)
    logger:debug("Creating slider for %s", control.id)
    config.persistent[control.id] = config.persistent[control.id] or control.sliderDefault
    local slider = mwse.mcm.createSlider(parent, {
        label = control.name .. ": %s",
        current = control.sliderDefault,
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable {
            id = control.id,
            table = config.persistent
        }
    })
    self.controlSliders = self.controlSliders or {}
    table.insert(self.controlSliders, slider)
    slider.callback = function()
        self:setShaderValue(control)
    end
end

function PhotoMenu:getControlsBlock()
    return self.menu:findChild("JOP.ControlsBlock")
end

function PhotoMenu:createControlsBlock(parent)
    local controlsBlock = parent:createBlock {id = "JOP.ControlsBlock"}
    controlsBlock.flowDirection = "top_to_bottom"
    controlsBlock.widthProportional = 1.0
    controlsBlock.autoHeight = true
    return controlsBlock
end

function PhotoMenu:createShaderControls(parent)
    local controlsBlock = self:getControlsBlock()
        or self:createControlsBlock(parent)
    if not self.artStyle.controls then
        logger:debug("ArtStyle %s has no controls", self.artStyle.name)
        return
    end
    logger:debug("Creating shader controls")
    local controls = self.artStyle.controls
    for _, controlName in ipairs(controls) do
        local control = config.controls[controlName]
        if not control then
            logger:error("Control %s not found", controlName)
        else
            self:createControlSlider(controlsBlock, control)
            self:setShaderValue(control)
        end
    end
end

function PhotoMenu:resetControls()
    logger:debug("Resetting controls")
    for shader in ipairs(self.shaders) do
        logger:debug("- shader %s", shader)
    end

    ---@param control JOP.ArtStyle.control
    for _, control in pairs(config.controls) do
        logger:debug("Control %s for shader %s", control.id, control.shader )
        if table.find(self.shaders, control.shader)then
            logger:debug("Shader is active, Resetting %s", control.id)
            config.persistent[control.id] = control.sliderDefault
            Shader.setUniform(
                control.shader,
                control.uniform,
                math.remap(control.sliderDefault, 0, 100, control.shaderMin, control.shaderMax)
            )
        end
    end
    local controlsBlock = self:getControlsBlock()
    if controlsBlock then
        controlsBlock:destroyChildren()
    end
    self:createShaderControls(self.menu)
end

function PhotoMenu:createResetButton(parent)
    logger:debug("Creating reset button")
    local button = parent:createButton {
        id = "JOP.ResetButton",
        text = "Reset"
    }
    button:register("mouseClick", function(e)
        self:resetControls()
    end)
end

function PhotoMenu:createCloseButton(parent)
    logger:debug("Creating close button")
    local button = parent:createButton {
        id = "JOP.CloseButton",
        text = "Close"
    }
    button:register("mouseClick", function(e)
        self:close()
        if self.closeCallback then
            logger:debug("Calling close callback")
            self.closeCallback()
        end
    end)
end

function PhotoMenu:setAspectRatio()
    local frameSize = config.frameSizes[self.canvasConfig.frameSize]
    if not frameSize then
        logger:error("Frame Size '%s' is not registered.", self.canvasConfig.frameSize)
        return
    end
    Shader.setUniform(
        config.shaders.window,
        "aspectRatio",
        frameSize.aspectRatio
    )
end

function PhotoMenu:initMGESettings()
    logger:debug("Initialising MGE Settings")
    --Enable rendering in menus so scroll wheel zoom works
    self.previousPauseRenderingInMenus = mge.render.pauseRenderingInMenus
    mge.render.pauseRenderingInMenus = false
    --Zoom
    self.previousZoomState = mge.camera.zoomEnable
    mge.camera.zoomEnable = true
    mge.camera.zoom = config.persistent.zoom / 100
    --PPL
    self.previousLightingMode = mge.getLightingMode()
    logger:debug("Setting previousLightingMode to: %s", table.find(mge.lightingMode, self.previousLightingMode))

    config.persistent.lightingMode = config.persistent.lightingMode or mge.getLightingMode()
    logger:debug("Setting lighting mode to: %s", table.find(mge.lightingMode, config.persistent.lightingMode))
    mge.setLightingMode(config.persistent.lightingMode)
end

function PhotoMenu:restoreMGESettings()
    logger:debug("Restoring MGE Settings")
    mge.render.pauseRenderingInMenus = self.previousPauseRenderingInMenus
    mge.camera.zoomEnable = self.previousZoomState
    logger:debug("restoring lighting mode to: %s", table.find(mge.lightingMode, self.previousLightingMode))
    mge.setLightingMode(self.previousLightingMode)
end

function PhotoMenu:enableShaders()
    logger:debug("Enabling shaders")
    for _, shaderId in ipairs(self.shaders) do
        logger:debug("- shader: %s", shaderId)
        Shader.enable(shaderId)
    end
end

function PhotoMenu:disableShaders()
    logger:debug("Disabling shaders")
    for _, shaderId in ipairs(self.shaders) do
        logger:debug("- shader: %s", shaderId)
        Shader.disable(shaderId)
    end
end


local function isTabPressed(e)
    return e.keyCode == tes3.scanCode.tab
end

local toggleMenuOnTab
--local restoreMenuOnReleaseRightClick
local scrollToZoom
function PhotoMenu:registerIOEvents()
    logger:debug("Registering IO events.")

    --When tab key is held down, hide the menu
    toggleMenuOnTab = function(e)
        if isTabPressed(e) then
            if self.isLooking then
                self.isLooking = false
                self:createMenu()
            else
                self.isLooking = true
                self:hideMenu()
            end
        end
    end

    --Use scroll wheel to affect zoom
    scrollToZoom = function(e)
        logger:debug("delta: %s", e.delta)
        local newVal = config.persistent.zoom + (e.delta * 0.1)
        config.persistent.zoom = math.clamp(newVal, 100, 1000)
        logger:debug("New Zoom: %s", config.persistent.zoom)
        mge.camera.zoom = config.persistent.zoom / 100
        if self.active then
            self.slider.elements.slider.widget.current = config.persistent.zoom - 100
            self.slider.elements.slider:findChild("PartScrollBar_elevator"):triggerEvent("mouseClick")
            self.slider:update()
            self.slider.elements.slider:updateLayout()
            self.menu:updateLayout()
        end
        logger:debug("New Zoom after slider: %s", config.persistent.zoom)
    end

    timer.frame.delayOneFrame(function()
        event.register("keyDown", toggleMenuOnTab)

        event.register(tes3.event.mouseWheel, scrollToZoom)
    end)
end

function PhotoMenu:unregisterIOEvents()
    logger:debug("Unregistering IO events.")
    event.unregister("keyDown", toggleMenuOnTab)
    --event.unregister("mouseButtonUp", restoreMenuOnReleaseRightClick)
    event.unregister(tes3.event.mouseWheel, scrollToZoom)
end


function PhotoMenu:createMenu()
    logger:debug("Creating Menu")
    local menu = tes3ui.createMenu {
        id = self.menuID,
        fixedFrame = true
    }
    menu.minWidth = 400
    menu.absolutePosAlignX = 0.02
    menu.absolutePosAlignY = 0.5
    self.menu = menu

    self:createHeader(menu)
    self:createZoomSlider(menu)
    self:createShaderControls(menu)
    self:createResetButton(menu)
    self:createCaptureButtons(menu)
    self:createCloseButton(menu)
    self.active = true
    tes3ui.enterMenuMode(menu.id)
end

function PhotoMenu:open()
    logger:debug("Opening Photo Menu")
    self:disablePlayerControls()
    self:initMGESettings()
    self:createMenu()
    self:setAspectRatio()
    self:enableShaders()
    self:registerIOEvents()
    self:resetControls()
end

--Destroy the menu
function PhotoMenu:hideMenu()
    tes3ui.leaveMenuMode()
    tes3ui.findMenu(self.menuID):destroy()
    self.active = false
end

--Destroy menu and restore all settings (shaders, controls etc)
function PhotoMenu:close()
    logger:debug("Closing Photo Menu")
    self:hideMenu()
    timer.delayOneFrame(function()
        self:enablePlayerControls()
        self:finishMenu()
    end)
end

--Reset events, settings, shaders
function PhotoMenu:finishMenu()
    self:unregisterIOEvents()
    self:restoreMGESettings()
    self:disableShaders()
end

function PhotoMenu:disablePlayerControls()
    logger:debug("Disabling player controls")
    --disable everything except vanity
    tes3.setPlayerControlState{ enabled = false}
end

function PhotoMenu:enablePlayerControls()
    logger:debug("Enabling player controls")
    tes3.setPlayerControlState{ enabled = true}
end

return PhotoMenu
