# The Joy of Painting
A mod that allows you to create paintings which can be sold or displayed in frames

## Painting Mechanic
- Painting quality determined by skill
- Place down an easel, add canvas
- Adjust camera to look at what you want to paint
- Camera lets you look around, zoom in/out
- Painting materialises onto canvas (using method described here: https://discord.com/channels/210394599246659585/766432467162497065/967851368406732860)
- Use ImageMagick to asynchronously convert screenshot into painting
- Use shader to create painted effect: apply shader, grab screenshot, remove shader
- Other active shaders can affect the final painting, such as Skoomaesthesia
- Final painting as painted canvas item with dynamically generated icon
- Painted Canvas can be attached to a picture frame and hung on a wall

## Items

### Easel
- Purchase or craft
- Place down where you want to paint
- Drop/attach via a menu, a blank canvas
- Once canvas is attached, menu option to begin painting

### Picture Frame
- Purchase or craft
- Place on a wall
- Square and 1:2 variants
- 1:2 frame can be rotated to accept landscape or portrait painting
- Drop a painting on it or via menu

### Canvas
- Purchase or craft
- Crafting recipe: Fabric + Wood
- Attaches to easel for painting

### Paint and Brushes
- Paint brush must be equipped
- Craft paint brush using wood and... hair?
- Paint must be refilled or purchased from merchants
  - The purpose of this is to limit how many paintings can be made for balance reasons.

## Painting Skill
- Uses Skills Module
- Determines gold value of painting
- How much paint is used per painting
- Could unlock new painting styles (shaders)
- Gain more experience painting novel objects in new locations

## Quests
Some NPCs will commission a painting for them. The painting will require a specific object to be in-frame, such as a location, creature, or NPC (including themselves!). Once commissioned, they may ask you to hang the painting up in their house in a suitable location. 

### Painting Subjects
When a scene is captured, add data about the subject of the painting based on what is in the scene:
- Cell/Region
- Time of day
- Weather
- NPCs
- Creatures
- Atrological objects: moon, sun etc
- Other objects: miscs, statics etc
- Unique locations (i.e defined XYZ coords representing something that can not be identified through generic objects)

### Request Examples
The data captured above can be combined to create requests for specific paintings:
- A landscape painting of Seyda Neen at Sunset
- A self portrait of the questgiver
- A painting of a scrib
- A landscape painting of Arkgnthand
- A "Still life" painting of a lute
- A saucy painting of the dancers at Desele's 


## Components Required

- Service to take screenshots and save them to file
  - Save painting
  - Save icon
  - Save average color (see: https://stackoverflow.com/questions/25488338/how-to-find-average-color-of-an-image-with-imagemagick)
- Camera controller
  - Disable player movement
  - Activate to pause game and enter menu
    - Confirm (Start Painting)
    - Zoom In
    - Zoom Out
    - Increase FOV
    - Decrease FOV
    - Vignette On/Off
    - Toggle PPL?
    - Rotate Canvas
    - Change Style (cycle between painting style shaders: oil, watercolor, sketch etc)
- Service to detect objects in front of player
  - Solution #1: 
    - Place 2d plane in front of player, size and distance such that it perfectly fits the frame on-screen
    - Perform rayTest from player to target, check if it intercepted the plane
  - Solution #2:
    - Check object position against player orientation
    - Use FOV to approximate whether it's within view
- Drag and Drop / menu functionality (Separate into framework from Ashfall?)
- Shader controller
  - List of "active" shaders
  - Active shaders enabled while in capture menu and when screenshot is taken, then deactivated
- Crafting recipes
- Quest services
- Picture Frame controller


## Magick commands
- https://imagemagick.org/script/command-line-options.php#paint - to simulate oil painting
- https://imagemagick.org/script/command-line-options.php#distort - To skew icon
