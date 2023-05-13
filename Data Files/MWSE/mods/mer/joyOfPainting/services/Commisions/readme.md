# Painting Commissions Mechanics

- Determine which NPCs can ask for commissions
  * Could allow any NPC, but put the greeting low enough so only those with generic greetings will trigger it
- Determine what kind of paintings a given NPC would want/could pay for
  * Check their gold level to determine painting type
  * Check class, skills, region to select a subject of the painting
- Trigger the commission dialog
  * If an NPC is chosen to ask for a commission, add a greeting that has "commission" topic
  * This adds the Commission topic to the player, and the topic becomes available for that NPC
  * Click the commission topic and the NPC describes what painting they want, and how much they'll pay


## Commission

Commissions have the following traits:
- A Scene
- An Orientation (portrait/landscape)
- A Canvas type (paper, parchment, canvas)
- A Paint type (charcoal, ink, watercolor, oil)
- An asking price

## Scene

### Scene Types
| Type | Description |
| :--- | :--- |
| Subject | A specific subject, like a person, place, or thing |
| Setting | A setting can have a region, time of day, weather |

## Subjects
```lua
{
    {
        name = "Guar",
        description = "a guar",
        requirements = function(reference)
            return reference.object.id == "guar"
        end,
    }
}
```
## Request
A request is a generated piece of dialog that describes the painting the NPC wants. It describes the scene, the orientation, the canvas, and the paint. It also includes the asking price.
