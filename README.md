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

### Frame
- Purchase or craft
- Place on a wall, then drop a painting onto it
- Then activate to start painting

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

## Quests
Some NPCs will commission a painting for them. The painting will require a specific object to be in-frame, such as a location, creature, or NPC (including themselves!). Once commissioned, they may ask you to hang the painting up in their house in a suitable location. 


## Components Required

- Service to take screenshots and save them to file
- Camera controller
- Drag and Drop / menu functionality (Separate into framework from Ashfall?)
- Shader controller
- Painterly shader
- Crafting recipes
- Quest services
- Picture Frame controller
