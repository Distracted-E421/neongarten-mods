# Neongarten Modding Session Context
**Last Updated**: 2026-01-22 14:00 CST

## Current State

### Project Setup ✅
- **Repository**: `neongarten-mods` on GitHub
- **Game Engine**: Godot 4.3.0 (editor: 4.5.1)
- **Game Path**: `/home/e421/.local/share/Steam/steamapps/common/Neongarten/`
- **Recovered Source**: `/home/e421/neongarten-mods/recovered/` (gitignored - copyrighted)

### Local Fixes Applied ✅
1. **Steam API Stub**: `recovered/player/godot_steam.gd` replaced with stub
   - Original referenced `Steam.*` which fails without GodotSteam plugin
   - Stub provides local achievement/stat storage
2. **Translations Disabled**: Line 422 in `project.godot` commented out
   - Binary `.translation` files couldn't be decompiled

### Tools Built ✅

#### Godot Harness (`tools/godot-harness/`)
| Tool | Purpose |
|------|---------|
| `gdharness` | Main CLI: project info, asset listing, validation |
| `asset-catalog` | Identify prologue vs modern assets |
| `samsung-capture` | Non-focus screenshot of Samsung TV |
| `gshot` | Quick screenshot tool |
| `gdre-nixos` | NixOS wrapper for gdsdecomp |

#### Samsung TV Capture
- **Coordinates**: `1920x1350` at `x=0, y=3280`
- **Why 1350 height**: Samsung TV at 125% scale needs extra pixels
- **Config**: `tools/godot-harness/samsung-config.json`
- **Usage**: `./samsung-capture capture [output.png]`

### Assets Analysis

#### Counts
- 322 3D models (.glb)
- 749 textures (.png)
- 77 structures (.tres)
- 123 scenes (.tscn)
- 51 scripts (.gd)

#### Prologue Assets Identified
**Pattern**: `lame_*` prefix

| Asset | Type |
|-------|------|
| lame_apartment | Building (structure, model, sprite) |
| lame_cafe | Building (structure, model, sprite) |
| lame_train_station | Building (structure, model, sprite) |

**Visual characteristics**: Muted colors, desaturated, cruder polygons

#### Modern Assets
**Pattern**: `T_UI_*` prefix (150 UI sprites confirmed)

### RNG System (For Slider Mod)
- **Core function**: `get_three_building_choices()` in `CityScreen.gd`
- **Rarity weights**: Based on `Structure.Rarities` enum (0=Common, 1=Uncommon, 2=Rare)
- **Modifiers**: Perks like SolarPunk, UncommonBuildings, RareBuildings
- **Detailed analysis**: `docs/RNG_SYSTEM_ANALYSIS.md`

### Display Setup
- **Samsung TV**: HDMI-A-5, 1920x1080@60Hz, 125% scale
- **Position in native pixels**: ~(0, 3280) in combined screenshot
- **Godot Editor**: Running on Samsung TV, fullscreen
- **Panels**: Left sidebar, bottom taskbar (visible in captures)

## Pending Tasks

### High Priority
1. **Refine Samsung TV capture coordinates** - Still has some bleed from monitor above
2. **Visual prologue asset sorting** - Need to see assets beyond `lame_*` pattern
3. **RNG Slider Mod** - UI to adjust tile appearance frequency and rarity

### Medium Priority
4. **stl-next Integration** - Design in `docs/STL_NEXT_INTEGRATION.md`
5. **Linux Native Port** - Steam stub allows non-Steam builds

### Lower Priority
6. **More prologue identification** - Many assets without `lame_*` still prologue-style

## Key Files

### Documentation
- `docs/TECHNICAL_RESEARCH.md` - Engine/format findings
- `docs/RNG_SYSTEM_ANALYSIS.md` - Building selection logic
- `docs/ART_GUIDELINES.md` - Faction colors, style guide
- `docs/LINUX_PORT_ANALYSIS.md` - Native Linux feasibility
- `docs/STL_NEXT_INTEGRATION.md` - Mod manager design

### Critical Scripts (in recovered/)
- `scripts/CityScreen.gd` - Main game logic, RNG
- `scripts/structure.gd` - Building properties
- `scripts/data_map.gd` - Game state management
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
# Capture Samsung TV (doesn't steal focus)
./tools/godot-harness/samsung-capture capture

# Get project info
./tools/godot-harness/gdharness info

# List buildings with RNG data
./tools/godot-harness/gdharness list-structures | jq '.structures[:5]'

# Analyze prologue assets
./tools/godot-harness/asset-catalog analyze

# Open Godot editor
godot --editor recovered/
```

## Session Notes
- User prefers dialog prompts over full message stops
- Playwright MCP too token-heavy for this workflow
- 6 monitors total, Samsung TV is for AI visual work
- NixOS with KDE Plasma Wayland
- Original 4.3 backup exists at `neongarten-(4.3)/` (gitignored)

