# KaidoTrainer - itch.io Release Checklist

## Project Status Summary

| Item | Status |
|------|--------|
| project.godot configured | ✅ Ready |
| Main scene exists | ✅ `scenes/agricommune.tscn` |
| All scripts present | ✅ 6 GDScript files |
| All asset folders exist | ✅ 20 asset folders verified |
| No hardcoded user paths | ✅ All paths use `res://` |
| Export presets created | ✅ `export_presets.cfg` |
| README.txt created | ✅ Controls included |
| Export templates installed | ❌ **BLOCKER** |

---

## BLOCKER: Export Templates Required

You need to install Godot 4.5.1 export templates before building.

### Option 1: Download via Godot Editor (Recommended)
1. Open Godot 4.5.1 (located at `~/Downloads/Godot.app`)
2. Go to **Editor → Manage Export Templates**
3. Click **Download and Install**
4. Wait for ~500MB download to complete

### Option 2: Manual Download
1. Go to: https://godotengine.org/download/archive/4.5.1-stable/
2. Download: `Godot_v4.5.1-stable_export_templates.tpz`
3. In Godot: **Editor → Manage Export Templates → Install from File**

---

## Pre-Export Cleanup (Saves ~113MB)

Remove these unnecessary files before exporting:

```bash
# Run from project folder
rm "xDeviruchi - 8-bit Fantasy  & Adventure Music (2021)/Separated Audio Files.zip"
rm "xDeviruchi - 8-bit Fantasy  & Adventure Music (2021)/READ THIS FIRST.pdf"
```

**Current project size:** 738MB
**After cleanup:** ~625MB
**Estimated export size:** 150-200MB per platform (compressed: ~80-100MB)

---

## Building Exports

### From Godot Editor (Easiest)
1. Open project in Godot
2. Go to **Project → Export...**
3. Select preset (Windows/macOS/Linux)
4. Click **Export Project**
5. Choose `builds/` folder

### From Command Line
```bash
GODOT="/Users/ianonuska/Downloads/Godot.app/Contents/MacOS/Godot"
PROJECT="/Users/ianonuska/OIP2/openworld RPG/kaidotrainer_full"

# Create output directories
mkdir -p "$PROJECT/builds/KaidoTrainer_Windows"
mkdir -p "$PROJECT/builds/KaidoTrainer_Mac"
mkdir -p "$PROJECT/builds/KaidoTrainer_Linux"

# Export Windows
"$GODOT" --headless --export-release "Windows" "$PROJECT/builds/KaidoTrainer_Windows/KaidoTrainer.exe"

# Export macOS
"$GODOT" --headless --export-release "macOS" "$PROJECT/builds/KaidoTrainer_Mac/KaidoTrainer.app"

# Export Linux
"$GODOT" --headless --export-release "Linux" "$PROJECT/builds/KaidoTrainer_Linux/KaidoTrainer.x86_64"
```

---

## Creating Zip Files for itch.io

After exporting, create zip archives:

```bash
cd "$PROJECT/builds"

# Windows
cd KaidoTrainer_Windows && zip -r ../KaidoTrainer_Windows.zip . && cd ..

# macOS (must preserve app bundle structure)
cd KaidoTrainer_Mac && zip -r ../KaidoTrainer_Mac.zip KaidoTrainer.app && cd ..

# Linux
cd KaidoTrainer_Linux && zip -r ../KaidoTrainer_Linux.zip . && cd ..
```

---

## itch.io Upload Settings

### Game Page Settings
- **Title:** KaidoTrainer
- **Classification:** Game
- **Kind of project:** Downloadable
- **Release status:** Released / In Development
- **Pricing:** Free / Name your price
- **Genre:** Educational, Adventure, RPG

### Upload Settings per File
| File | Platform | Architecture |
|------|----------|--------------|
| KaidoTrainer_Windows.zip | Windows | x86_64 |
| KaidoTrainer_Mac.zip | macOS | Universal |
| KaidoTrainer_Linux.zip | Linux | x86_64 |

### Recommended Tags
- pixel-art
- educational
- electronics
- retro
- singleplayer
- controller-support
- stardew-valley-like

---

## Pre-Upload Testing Checklist

### For Each Build:
- [ ] Game launches without crash
- [ ] Title screen appears correctly
- [ ] Can start new game
- [ ] Movement works (keyboard)
- [ ] Movement works (controller)
- [ ] Audio plays
- [ ] Can interact with NPCs
- [ ] Can enter buildings
- [ ] Save/load works (if applicable)

### Quick Smoke Test:
1. Launch game
2. Start new game
3. Walk around farm area
4. Talk to grandmother
5. Enter shed
6. Exit and walk to another area

---

## File Sizes Reference

Expected approximate sizes:
- **Windows:** 150-180MB (zipped: ~80MB)
- **macOS:** 160-190MB (zipped: ~85MB)
- **Linux:** 150-180MB (zipped: ~80MB)

If exports are much larger, check:
- Unnecessary asset files included
- Music files not compressed
- Debug symbols included (use Release export)

---

## Project Configuration Summary

**From project.godot:**
```
Name: KaidoTrainer
Resolution: 480x320 (2x window: 960x640)
Renderer: gl_compatibility (OpenGL 3.3)
Stretch mode: viewport
Main scene: res://scenes/agricommune.tscn
```

**Asset Paths Used:**
- `res://Sprout Lands - Sprites - Basic pack/`
- `res://Ninja Adventure - Asset Pack/`
- `res://mystic_woods_free_2.2/`
- `res://player_sprite_and_animations/`
- `res://xDeviruchi - 8-bit Fantasy  & Adventure Music (2021)/`
- Various NPC sprite folders

---

## Quick Commands Reference

```bash
# Set paths
GODOT="/Users/ianonuska/Downloads/Godot.app/Contents/MacOS/Godot"
PROJECT="/Users/ianonuska/OIP2/openworld RPG/kaidotrainer_full"

# Open project in Godot
"$GODOT" --editor --path "$PROJECT"

# Run game directly
"$GODOT" --path "$PROJECT"

# Check Godot version
"$GODOT" --version
```

---

## Support

- **Company:** ONUSKA & BROWN Technologies Ltd.
- **Copyright:** 2026

---

*Generated: 2026-01-11*
