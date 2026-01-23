# Neongarten Modding Session Context
**Last Updated**: 2026-01-23 15:30 CST

## 🎉 MAJOR BREAKTHROUGH: EIS Input Working!

**We have successfully implemented unfocused input via Wayland portals!**

The AI can now:
1. ✅ Take screenshots of the Dell monitor (where Godot runs)
2. ✅ Move the cursor to absolute coordinates via EIS
3. ✅ Click at specific positions
4. ✅ All without requiring window focus!

This unlocks true AI interaction with the Godot editor.

## Current State

### Project Setup ✅
- **Repository**: `neongarten-mods` on GitHub
- **Game Engine**: Godot 4.3.0 (editor: 4.5.1)
- **Game Path**: `/home/e421/.local/share/Steam/steamapps/common/Neongarten/`
- **Recovered Source**: `/home/e421/neongarten-mods/recovered/` (gitignored - copyrighted)

### Local Fixes Applied ✅
1. **Steam API Stub**: `recovered/player/godot_steam.gd` replaced with stub
2. **Translations Disabled**: Line 422 in `project.godot` commented out

### Tools Built ✅

#### Portal Input Tool (`tools/portal-input/`)
**The breakthrough tool for Wayland unfocused input!**

| Command | Purpose |
|---------|---------|
| `eis` | Show EIS regions and coordinate mapping |
| `eis-send -x X -y Y` | Move cursor to absolute position |
| `eis-send -x X -y Y --click` | Move and left-click |
| `eis-send -x X -y Y --shake` | Move with visual shake |
| `status` | Check portal availability |
| `interactive` | Interactive legacy mode |

**Build**: `cd tools/portal-input && cargo build --release`

#### Godot Harness (`tools/godot-harness/`)
| Tool | Purpose |
|------|---------|
| `gdharness` | Main CLI: project info, asset listing |
| `asset-catalog` | Identify prologue vs modern assets |
| `ai-monitor-capture` | Non-focus screenshot of Dell monitor |

### Display Setup - AI Monitor

**Dell E2420H** (Top-left position, Priority 2)
- **Resolution**: 1920x1080 at 125% scale
- **Screenshot Region**: `(0, 1570)` for `3070x1750` capture area
- **EIS Region [1]**: x: 0-1536, y: 796-1660, scale 1.25

### EIS Region Mapping

| Region | X | Y | Width | Height | Scale | Description |
|----|----|----|----|----|----|-----|
| [0] | 1536 | 700 | 1707 | 960 | 1.5 | Main monitor (center) |
| [1] | 0 | 796 | 1536 | 864 | 1.25 | **Dell E2420H - AI Monitor** |
| [2] | 4323 | 796 | 1080 | 1920 | 1.0 | Right portrait |
| [3] | 0 | 1660 | 1536 | 864 | 1.25 | Samsung TV |
| [4] | 1536 | 1660 | 1536 | 864 | 1.25 | Bottom-center |
| [5] | 3243 | 0 | 1080 | 1920 | 1.0 | Top-right portrait |

### How to Target Dell Monitor (Godot)
- **EIS X range**: 0 to 1536
- **EIS Y range**: 796 to 1660
- **Center point**: (768, 1228)
- **Title bar area**: y ~800-850
- **Content area**: y ~850-1600

## AI Interaction Workflow

```bash
# 1. Capture current state
./tools/godot-harness/ai-monitor-capture capture

# 2. Analyze screenshot for target coordinates
# (EIS coords = physical coords in region [1])

# 3. Click at identified position
./tools/portal-input/target/release/portal-input eis-send -x 400 -y 1000 --click

# 4. Verify result
./tools/godot-harness/ai-monitor-capture capture
```

## Pending Tasks

### High Priority
1. **Daemon mode for portal-input** - Avoid repeated consent dialogs
2. **Keyboard input via EIS** - Add key subcommand
3. **RNG Slider Mod** - UI to adjust tile appearance frequency

### Medium Priority
4. **Complete Linux port testing** - Game should run natively
5. **stl-next Integration** - Godot PCK mod management

## Key Files

### New/Updated This Session
- `docs/AI_INTERACTION_STRATEGIES.md` - Full EIS documentation
- `tools/portal-input/` - EIS input tool (Rust)
- `tools/godot-harness/ai-monitor-capture` - Updated for Dell monitor
- `tools/godot-harness/ai-monitor-config.json` - Dell monitor coordinates

### Critical Scripts (in recovered/)
- `scripts/CityScreen.gd` - Main game logic, RNG
- `scripts/structure.gd` - Building properties
- `player/godot_steam.gd` - Steam stub (modified)

### Faction Colors
| Faction | Color | Hex |
|---------|-------|-----|
| Corp | Golden | `#BC9A51` |
| Illegal | Red | `#B53445` |
| Govt | Blue | `#4480B2` |
| Volt | Green | `#81A770` |
| Neutral | Purple-gray | `#887EA3` |

## Quick Commands

```bash
# Take screenshot of Godot on Dell monitor
./tools/godot-harness/ai-monitor-capture capture

# Test EIS input - move and shake
./tools/portal-input/target/release/portal-input eis-send -x 768 -y 1200 --shake

# Test EIS input - move and click
./tools/portal-input/target/release/portal-input eis-send -x 768 -y 1000 --click

# Get project info
./tools/godot-harness/gdharness info

# Open Godot editor
godot --editor recovered/
```

## Session Notes
- **EIS/libei**: Successfully implemented for Wayland input injection
- **KDE Limitation**: RemoteDesktop sessions can't persist (consent each time)
- **Workaround Needed**: Daemon mode to keep session alive
- **User prefers**: Dialog prompts over full message stops
- **Dell Monitor**: Now the primary AI interaction display
