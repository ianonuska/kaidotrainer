# KaidoTrainer - Claude Code Context

## What This Is
Educational handheld gaming device teaching kids electronics through physical circuit building. Players build real circuits on a breadboard, camera + TensorFlow detects components, AI tutor provides feedback. Think GameBoy meets electronics kit.

**Company:** ONUSKA & BROWN Technologies Ltd.  
**Stage:** Pre-seed fundraising  
**Hardware:** Raspberry Pi Zero 2W + Pi Camera + TensorFlow Lite

---

## Repository Structure

```
kaidotrainer_full/
├── agricommune.gd          # Main game script (~7,300 lines)
├── DialogueData.gd         # NPC dialogue content
├── AreaDrawing.gd          # Environment rendering
├── UIDrawing.gd            # Menus, popups, HUD
├── CombatSystem.gd         # Arkham-style combat
├── StampedeSystem.gd       # Animal dodging minigame
├── InteriorScenes.gd       # Building interiors
└── [Asset folders]         # Sprite packs below
```

### Asset Paths
```gdscript
const SPROUT_PATH = "res://Sprout Lands - Sprites - Basic pack/"
const NINJA_PATH = "res://Ninja Adventure - Asset Pack/Actor/Characters/"
const NINJA_ANIMALS_PATH = "res://Ninja Adventure - Asset Pack/Actor/Animals/"
const OBJECTS_PATH = "res://Sprout Lands - Sprites - Basic pack/Objects/"
const TILESET_PATH = "res://Sprout Lands - Sprites - Basic pack/Tilesets/"
```

---

## Display & Rendering

- **Target:** 320×480 (portrait), rendered at 480×320 with GAME_ZOOM = 2.0
- **Style:** "Modern 8-bit" - pixel art, Stardew Valley scale
- Y-sorted rendering for proper depth
- All drawing in `_draw()` function using Godot's immediate mode

---

## Game Areas (5 total)

| Area | Location | Key Features |
|------|----------|--------------|
| Farm | Starting area | Grandmother's house, chicken coop, well, shed, radiotower |
| Cornfield | Up road | Farmer Wen's farmhouse, LED chain circuit |
| Lakeside | Down road | Dock, rocks, fishing NPCs |
| Town Center | Right road | Shop, Town Hall, Bakery (all enterable) |
| Stampede | Left road | Endless animal dodging minigame |

### Area Transitions
- Roads at screen edges lead to other areas
- Screen transition uses fade effect (screen_transition_alpha)

---

## Game Modes (enum GameMode)

```
INTRO, EXPLORATION, SHED_INTERIOR, PHOTOGRAPH, BUILD_SCREEN,
SCHEMATIC_POPUP, BACKPACK_POPUP, JOURNAL_VIEW, COMBAT,
RADIOTOWER_INTERIOR, RADIOTOWER_VIEW, STAMPEDE, NIGHTFALL,
ENDING_CUTSCENE, REGION_COMPLETE, SHOP_INTERIOR, TOWNHALL_INTERIOR,
BAKERY_INTERIOR, PAUSE_MENU
```

---

## Core Systems

### Movement & Collision
- Player position: `player_pos: Vector2`
- Collision check: `check_collision(new_pos)` returns bool
- Collisions defined in `building_collisions: Array` as Rect2 objects
- Area-specific collisions handled in `check_collision()` with switch on `current_area`

### Kaido (AI Companion)
- Follows player with trail delay (45 frames behind)
- 5 emotion states: neutral, happy, worried, thinking, excited
- Floating/bobbing animation
- Position: `kaido_pos: Vector2`

### NPCs
- Each area has NPC arrays: `cornfield_npcs`, `lakeside_npcs`, `town_npcs`
- Idle animations: breathing, swaying, blinking
- Dialogue triggered by proximity + interact button

### Stealth System
- `awareness_level` (0-100) fills when patrol sees player
- `hiding_spots: Array` of Vector2 safe positions
- Decay when hidden, fill when spotted

---

## Code Patterns

### Adding a New Drawing Function
```gdscript
func draw_thing(x: float, y: float):
    if tex_thing:
        var src = Rect2(0, 0, 16, 16)  # Source rect from spritesheet
        var dest = Rect2(x - 8, y - 8, 16, 16)  # Centered on position
        draw_texture_rect_region(tex_thing, dest, src)
```

### Adding a New NPC
```gdscript
# In the area's NPC array
var area_npcs: Array = [
    {"pos": Vector2(100, 200), "name": "NPC Name", "dialogue": "What they say"},
]
```

### Adding a Collision
```gdscript
# In building_collisions array
Rect2(x, y, width, height),  # Comment explaining what it's for
```

### Sign Drawing (existing patterns)
- `draw_road_sign(x, y, text)` - horizontal wooden sign
- `draw_road_sign_vertical(x, y, text)` - vertical post sign
- Signs have 6px char width, 12px height, wooden post underneath

---

## Key Variables Quick Reference

| Variable | Type | Purpose |
|----------|------|---------|
| `current_mode` | GameMode | What screen/state we're in |
| `current_area` | Area | Which map area (FARM, CORNFIELD, etc.) |
| `player_pos` | Vector2 | Player world position |
| `kaido_pos` | Vector2 | Companion position |
| `camera_offset` | Vector2 | For scrolling larger areas |
| `building_collisions` | Array[Rect2] | Collision rectangles |
| `awareness_level` | float | Stealth detection meter |

---

## Important Line Number Ranges

These shift as code changes, but approximate locations:

- **Constants & Enums:** Lines 1-80
- **Area NPCs:** Lines 110-150
- **Building collisions:** Lines 255-290
- **Player state vars:** Lines 200-250
- **Stealth system:** Lines 315-335
- **check_collision():** Search for `func check_collision`
- **Draw functions:** Last ~2000 lines of file

---

## Circuit Detection (TODO - Phase 1)

Integration pattern for Pi camera:
```gdscript
func check_circuit():
    var output = []
    OS.execute("python3", ["detect_circuit.py"], output)
    var result = output[0] if output.size() > 0 else ""
    
    match result.strip_edges():
        "LED_ON": circuit_complete = true
        "LED_REVERSED": show_hint("Long leg goes to positive")
        "MISSING_RESISTOR": show_hint("Don't forget the resistor!")
```

---

## DO NOT CHANGE WITHOUT ASKING

1. **Sprite positions** 
2. **Collision rectangle positions** - User handles placement through testing
3. **Display constants** - SCREEN_WIDTH, SCREEN_HEIGHT, GAME_ZOOM are fixed
4. **Asset paths** - These match the actual folder structure

---

## Common Tasks

### "Add an animal to [area]"
1. Load texture in `_ready()` with other animal textures
2. Add to area's animal spawn in appropriate draw function
3. Use roaming animal system pattern (continuous walking)

### "Add an NPC to [area]"
1. Add entry to area's NPC array with pos, name, dialogue
2. NPC will automatically get idle animations from existing system

### "Add a building/object"
1. Draw it in the area's draw function
2. Add collision Rect2 to `building_collisions` or area-specific collision
3. If enterable, add door position and interior mode handling

### "Fix a collision"
1. Find the Rect2 in `building_collisions` array (around line 255-290)
2. Or find area-specific collision in `check_collision()` function
3. Adjust x, y, width, height values

---

## Testing

Run in Godot 4.x. Controller support included (PlayStation button prompts).
Target device is Raspberry Pi, but develops on desktop.

---

## Story Context

The game is set in "Agricommune" - a farming village in the world of Terra Machina. Player is a child who discovers Kaido (an AI companion) and learns electronics to help the village. Story progresses through circuit-building quests.

Full story spans multiple regions (Agricommune is first), with 5 circuits per region teaching progressively complex electronics concepts.
