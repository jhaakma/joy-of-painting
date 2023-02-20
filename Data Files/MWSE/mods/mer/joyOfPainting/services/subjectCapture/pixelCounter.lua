local this = {}

local ffi = require("ffi")
ffi.cdef [[
    typedef struct {
        unsigned char b;
        unsigned char g;
        unsigned char r;
        unsigned char a;
    } Pixel;

    typedef struct {
        void* vtable;
        int refCount;
        unsigned int format;
        unsigned int channelMasks[4];
        unsigned int bitsPerPixel;
        unsigned int compareBits[2];
        void* palette;
        Pixel* pixels;
        unsigned int* widths;
        unsigned int* heights;
        unsigned int* offsets;
        unsigned int mipMapLevels;
        unsigned int bytesPerPixel;
        unsigned int revisionID;
    } NiPixelData;
]]

local function _countActivePixels(pixelData)
    local width = pixelData.widths[0]
    local height = pixelData.heights[0]
    local pixels = pixelData.pixels

    local count = 0
    local total = 0
    for i = 0, width * height do
        local pixel = pixels[i]
        if pixel.b >= 128 then
            count = count + 1
        end
        total = total + 1
    end

    return count, total
end

local function _countEdgePixels(pixelData)
    local width = pixelData.widths[0]
    local height = pixelData.heights[0]
    local pixels = pixelData.pixels

    local count = 0
    local total = 0
    --top and bottomw row
    for i = 0, width - 1 do
        local pixel = pixels[i]
        if pixel.b >= 128 then
            count = count + 1
        end

        local pixel = pixels[(height - 1) * width + i]
        if pixel.b >= 128 then
            count = count + 1
        end
        total = total + 2
    end
    --left and right column, excluding corners
    for i = 1, height - 2 do
        local pixel = pixels[i * width]
        if pixel.b >= 128 then
            count = count + 1
        end
        local pixel = pixels[i * width + width - 1]
        if pixel.b >= 128 then
            count = count + 1
        end
        total = total + 2
    end
    return count, total
end



---@param pixelData niPixelData
function this.countActivePixels(pixelData)
    local ptr = mwse.memory.convertFrom.niObject(pixelData) ---@diagnostic disable-line
    local pixelDataFFI = ffi.cast("NiPixelData*", ptr)[0]
    return _countActivePixels(pixelDataFFI)
end

function this.countActiveEdgePixels(pixelData)
    local ptr = mwse.memory.convertFrom.niObject(pixelData) ---@diagnostic disable-line
    local pixelDataFFI = ffi.cast("NiPixelData*", ptr)[0]
    return _countEdgePixels(pixelDataFFI)
end

return this

