# Deploying KaidoTrainer to BatleXP G350

## Overview

Your Godot 4.5 project can run on the G350 via **PortMaster** using the **WestonPack** runtime.

**Device:** BatleXP G350
**SoC:** RK3326 (ARM Cortex-A35)
**Screen:** 640×480, 3.5" IPS
**OS:** ArkOS

## Prerequisites

- G350 with ArkOS installed
- SD card with PortMaster installed
- Godot 4.5 editor on your Mac

---

## Step 1: Configure Export Settings in Godot

### 1.1 Add Export Preset

In Godot, go to **Project → Export** and add a **Linux** preset.

### 1.2 Configure Export Settings

| Setting | Value |
|---------|-------|
| **Architecture** | `arm64` |
| **Export Mode** | `Export PCK/ZIP` |
| **Embed PCK** | Disabled |

### 1.3 Texture Compression (Critical!)

Go to **Project → Project Settings → Rendering → Textures** and ensure:

- **Vram Compression → Import ETC2/ASTC** = `true`

Then in the Export dialog under **Textures**:
- Enable **ETC2/ASTC** compression

> ⚠️ Without ETC2/ASTC, you'll get "missing image asset" errors on ARM.

### 1.4 Renderer Settings

In **Project Settings → Rendering → Renderer**:
- Set **Rendering Method** to `mobile` or `gl_compatibility`

> The G350's Mali-G31 doesn't support Vulkan, so you need OpenGL ES.

---

## Step 2: Export the Game

1. In Godot, go to **Project → Export**
2. Select your Linux/arm64 preset
3. Click **Export PCK/ZIP**
4. Name it `kaidotrainer.pck`
5. Save to a working folder

---

## Step 3: Create the Port Structure

Create this folder structure:

```
KaidoTrainer/
├── KaidoTrainer.sh          # Launch script
├── kaidotrainer.pck         # Your exported game
└── gamecontrollerdb.txt     # Controller mappings (optional)
```

### 3.1 Create Launch Script

Create `KaidoTrainer.sh`:

```bash
#!/bin/bash

# SPDX-License-Identifier: MIT

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

# Game info
GAMEDIR="/$directory/ports/KaidoTrainer"
CONFDIR="$GAMEDIR/conf"

# Create config directory
mkdir -p "$CONFDIR"
cd "$GAMEDIR"

# Set up save data location
export XDG_DATA_HOME="$CONFDIR"

# Runtime requirements
runtime="godot45"
weston_runtime="westonpack"

# Check and mount runtimes
if [ ! -f "$controlfolder/libs/${runtime}.squashfs" ]; then
    echo "Missing Godot 4.5 runtime!" > "$GAMEDIR/error.log"
    exit 1
fi

if [ ! -f "$controlfolder/libs/${weston_runtime}.squashfs" ]; then
    echo "Missing WestonPack runtime!" > "$GAMEDIR/error.log"
    exit 1
fi

# Mount runtimes
$ESUDO mkdir -p /tmp/godot /tmp/weston
$ESUDO mount -t squashfs "$controlfolder/libs/${runtime}.squashfs" /tmp/godot
$ESUDO mount -t squashfs "$controlfolder/libs/${weston_runtime}.squashfs" /tmp/weston

# Set up environment
export LD_LIBRARY_PATH="/tmp/godot/lib:/tmp/weston/lib:$LD_LIBRARY_PATH"
export PATH="/tmp/godot/bin:/tmp/weston/bin:$PATH"

# Run the game
$GPTOKEYB "godot" -c "$GAMEDIR/kaidotrainer.gptk" &
/tmp/weston/westonwrap.sh drm gl kiosk virgl -- /tmp/godot/bin/godot \
    --resolution ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT} \
    -f \
    --rendering-driver opengl3_es \
    --audio-driver ALSA \
    --main-pack "$GAMEDIR/kaidotrainer.pck"

# Cleanup
$ESUDO umount /tmp/godot
$ESUDO umount /tmp/weston
$ESUDO kill -9 $(pidof gptokeyb)
$ESUDO systemctl restart oga_events &

# Restore display
printf "\033c" > /dev/tty0
```

### 3.2 Create Controller Mapping

Create `kaidotrainer.gptk` for controller input:

```
# KaidoTrainer Controls
# Maps G350 buttons to keyboard inputs

back = esc
start = enter
a = x
b = z
x = c
y = v
l1 = q
r1 = e
l2 =
r2 =
up = up
down = down
left = left
right = right
left_analog_up = up
left_analog_down = down
left_analog_left = left
left_analog_right = right
```

> Adjust based on your game's input map in Godot.

---

## Step 4: Install on G350

### 4.1 Download Required Runtimes

If not already installed, download from PortMaster:

**On the G350:**
1. Open PortMaster
2. Go to **Options → Runtime Manager**
3. Download:
   - `godot45` (Godot 4.5 runtime)
   - `westonpack` (WestonPack compatibility layer)

**Or manually download:**

From [PortMaster-New Runtimes](https://github.com/PortsMaster/PortMaster-New/tree/main/runtimes):
- `godot45-aarch64.squashfs`
- `westonpack.squashfs`

Place in: `/roms/ports/PortMaster/libs/`

### 4.2 Copy Game Files

Copy your `KaidoTrainer/` folder to the G350's SD card:

```
SD Card/
└── ports/
    └── KaidoTrainer/
        ├── KaidoTrainer.sh
        ├── kaidotrainer.pck
        └── kaidotrainer.gptk
```

### 4.3 Set Execute Permission

On the G350 via SSH or terminal:
```bash
chmod +x /roms/ports/KaidoTrainer/KaidoTrainer.sh
```

---

## Step 5: Launch and Test

1. On G350, navigate to **Ports** in EmulationStation
2. Select **KaidoTrainer**
3. Game should launch!

---

## Troubleshooting

### Black Screen
- Check renderer is set to `mobile` or `gl_compatibility`
- Ensure ETC2/ASTC textures are enabled
- Check `/roms/ports/KaidoTrainer/error.log`

### Missing Runtime Error
- Download runtimes via PortMaster → Options → Runtime Manager
- Or manually place `.squashfs` files in `PortMaster/libs/`

### Controls Not Working
- Edit `kaidotrainer.gptk` to match your Godot input actions
- Check Godot's input map names

### Performance Issues
- The RK3326 is limited - keep graphics simple
- Target 30 FPS
- Reduce particle effects
- Use simpler shaders

### Resolution Issues
Your game is configured for 480×320. The G350 is 640×480.
Options:
1. Let it scale (may look stretched)
2. Add black bars (letterboxing)
3. Update your project settings for 640×480

---

## Display Configuration

For proper 640×480 display, update your Godot project:

**Project Settings → Display → Window:**
```
viewport_width = 640
viewport_height = 480
stretch/mode = "canvas_items"
stretch/aspect = "keep"
```

Or keep 480×320 and let the script handle scaling.

---

## Resources

- [PortMaster Porting Guide](https://portmaster.games/porting.html)
- [WestonPack Wiki](https://github.com/binarycounter/Westonpack/wiki)
- [Godot 4 Example Script](https://github.com/binarycounter/Westonpack/wiki/Godot-4-Example)
- [PortMaster Runtimes](https://github.com/PortsMaster/PortMaster-New/tree/main/runtimes)
- [ArkOS Wiki](https://github.com/christianhaitian/arkos/wiki)

---

## Quick Reference

| Task | Location |
|------|----------|
| Export PCK | Godot → Project → Export → Linux arm64 |
| Runtimes | G350: PortMaster → Options → Runtime Manager |
| Game folder | SD Card: `/roms/ports/KaidoTrainer/` |
| Libs folder | SD Card: `/roms/ports/PortMaster/libs/` |
