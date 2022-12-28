local interop = require("mer.joyOfPainting.interop")

local frameSizes = {
    {
        id = "square",
        width = 100,
        height = 100,
    },
    {
        id = "tall",
        width = 9,
        height = 16,
    },
    {
        id = "wide",
        width = 16,
        height = 9,
    },

    {
        id = "paper_portrait",
        width = 100,
        height = 120
    }
}

for _, frameSize in ipairs(frameSizes) do
    interop.registerFrameSize(frameSize)
end

local frames = {
    {
        id = "jop_frame_sq_01",
        frameSize = "square"
    },
    {
        id = "jop_frame_w_01",
        frameSize = "wide"
    },
    {
        id = "jop_frame_t_01",
        frameSize = "tall"
    },
}
event.register(tes3.event.initialized, function()
    for _, frame in ipairs(frames) do
        interop.registerFrame(frame)
    end
end)