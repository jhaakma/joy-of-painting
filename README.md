# The Joy of Painting ALPHA
This mod allows you to create paintings which can be sold or displayed in frames.

## Requirements ##

### Morrowind Install Location
Morrowind **must be installed outside of `Program Files/`**. Windows locks down permissions on software installed in that folder and this causes issues with a number of mods and mod organisers, so it's good practice to avoid installing Morrowind there anyway, but for Joy of Painting this is an absolute must. Joy of Painting reads, edits and writes image files in your `Data Files/Textures` folder and can not do so if Morrowind is installed in `Program Files/`.

### ImageMagick
ImageMagick is an image editing tool, and it must be installed on your machine so it can be used by this mod.

An installer is included with this mod in the `Data Files\JoyOfPaintingResources` folder, or you can download it here: https://imagemagick.org/archive/binaries/ImageMagick-7.1.0-55-Q16-HDRI-x64-dll.exe

### MGE XE v0.15.0 or later
Requires MGE XE v0.15 or later in order to capture the screenshots used for paintings.

### Morrowind Script Extender
Ensure the latest MWSE is installed by running the `MWSE-Update.exe` file which comes with MGE XE, found in your `Morrowind` directory.

### Skills Module
Skills module is required for the painting/artistry skill.
Skills Module can be found here: https://www.nexusmods.com/morrowind/mods/46034

### The Crafting Framework
The Crafting Framework is required in order to craft art supplies.
The Crafting Framework can be found here: https://www.nexusmods.com/morrowind/mods/51009

### Ashfall (ALPHA release only)
This dependency is only required during the alpha release, as currently the only way to get canvases and easels is to bushcraft them.
Ashfall can be found here: https://www.nexusmods.com/morrowind/mods/49057


## How to Play

*These instructions are for the ALPHA release, and will be subject to change.*

In order to start painting, you will need an easel and a canvas. Craft these in the Ashfall bushcrafting menu.

When you've crafted your easel, place it down in front of the subject you want to paint. Activate the easel and use the menu to attach a canvas, then select "Draw/Paint" and select an art style. This will open the painting UI.

Toggle between moving the camera and nagivating the menu using `right click`. use the `scroll wheel` to zoom in and out, and use the `brightness` and `contrast` sliders to adjust the image.

Tips:
- Paintings tend to look best when there is a strong contrast between the subject and the background.
- For charcoal sketches, strong contrast will create a better effect
- For ink sketches, turn up the brightness until only outlines remain
- When you start out, your painting skill will be very low, which affects the visible quality of your paintings.
- To test out a higher painting skill right away, enter the following in the Lua console:
    ```
      jop.skills.painting.value = 60
    ```
