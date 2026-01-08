# KaidoTrainer - Agricommune

## Quick Start

1. Open Godot 4.x
2. Import this project (select project.godot)
3. Press F5 to run
4. WASD to move, E to interact

The game works with colored placeholder graphics. To add real pixel art, follow the asset guide below.

---

## Controls

| Key | Action |
|-----|--------|
| W/A/S/D | Move |
| E / Space | Interact / Advance dialogue |
| Arrow Keys | Also move |

---

## Free Assets to Download

### 1. Sprout Lands (RECOMMENDED - Matches style perfectly)

**Download:** https://cupnooble.itch.io/sprout-lands-asset-pack

Free version includes:
- Character sprites
- Farm tiles (grass, dirt, crops)
- Buildings
- Objects (fences, trees)

After downloading, extract and copy:
```
Sprout Lands/Characters/Basic Charakter Spritesheet.png → assets/characters/
Sprout Lands/Tilesets/Grass.png → assets/tiles/
Sprout Lands/Objects/ → assets/objects/
```

---

### 2. Ninja Adventure (Huge free pack)

**Download:** https://pixel-boy.itch.io/ninja-adventure-asset-pack

Great for:
- Extra characters
- UI elements
- Items

---

### 3. Kenney Assets (100% free, public domain)

**Download:** https://kenney.nl/assets

Good packs:
- Tiny Town
- Tiny Dungeon
- Game Icons

---

## Folder Structure

Put downloaded assets here:

```
kaidotrainer_full/
├── project.godot
├── scenes/
│   └── agricommune.tscn
├── scripts/
│   └── agricommune.gd
└── assets/
	├── characters/
	│   ├── player_down.png
	│   ├── player_up.png
	│   ├── player_left.png
	│   ├── player_right.png
	│   ├── kaido.png
	│   └── grandmother.png
	├── tiles/
	│   ├── grass.png
	│   ├── dirt.png
	│   └── water.png
	├── objects/
	│   ├── tree.png
	│   ├── fence.png
	│   ├── house.png
	│   └── crops.png
	└── ui/
		├── dialogue_box.png
		├── portrait_kaido.png
		└── portrait_grandmother.png
```

---

## Converting Sprite Sheets

Most asset packs come as sprite sheets (many sprites in one image).

To use individual sprites:

### Option A: Split in image editor
1. Open sprite sheet in Photoshop/GIMP/Aseprite
2. Cut out individual sprites
3. Save as separate PNGs

### Option B: Use Godot's AtlasTexture
1. Import the sprite sheet
2. Create AtlasTexture resources
3. Define regions for each sprite

### Option C: Use AnimatedSprite2D
1. Import sprite sheet
2. Set up SpriteFrames resource
3. Define animation frames

For now, the game uses colored rectangles as placeholders, so you can play immediately without any assets.

---

## What Each Asset Is For

| Asset | Used For |
|-------|----------|
| player_down/up/left/right.png | Player walking in 4 directions |
| kaido.png | Your robot companion |
| grandmother.png | NPC at the farm |
| grass.png | Ground tileset |
| dirt.png | Path tileset |
| house.png | Farmhouse building |
| tree.png | Decoration |
| fence.png | Farm boundaries |
| crops.png | Farm field decoration |
| dialogue_box.png | UI background for dialogue |
| portrait_*.png | Character faces in dialogue |

---

## Creating Custom Kaido Sprite

Kaido should be:
- 32x32 pixels or smaller
- Teal/cyan colored robot
- Cute, friendly appearance
- Antenna on head
- Simple rectangular body

You can commission this or I can provide a simple pixel art version.

---

## Next Steps

1. Download Sprout Lands free pack
2. Extract character sprites into assets/characters/
3. The game will automatically use them if named correctly
4. Or keep playing with placeholder graphics!

---

## Troubleshooting

**Game window is tiny:**
- The viewport is 480x320 (retro size)
- Window is scaled 2x to 960x640
- This is intentional for pixel art

**Sprites not loading:**
- Check file names match exactly
- Check files are in correct folders
- Check .png extension

**Movement feels slow:**
- Edit player_speed in agricommune.gd
- Default is 120, try 150 or 180

---

*KaidoTrainer v0.1 - January 2026*
