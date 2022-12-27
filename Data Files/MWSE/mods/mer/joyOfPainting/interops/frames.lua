local interop = require("mer.joyOfPainting.interop")

local frameSizes = {
    {
        id = "square",
        width = 512,
        height = 512,
    },
    {
        id = "tall",
        width = 512,
        height = 1024,
    },
    {
        id = "wide",
        width = 1024,
        height = 512,
    },
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
for _, frame in ipairs(frames) do
    interop.registerFrame(frame)
end