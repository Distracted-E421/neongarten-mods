# Neongarten Modding - Quick Start Guide

## 🎮 Game Info

- **Engine**: Godot 4.3.0
- **Developer**: Josh Galecki (Moonroof Studios)
- **Game Path**: `~/.local/share/Steam/steamapps/common/Neongarten/`

## 🚀 Quick Setup

```bash
# 1. Enter development environment
cd ~/neongarten-mods
nix develop

# 2. Install gdsdecomp (one-time setup)
./tools/setup-gdsdecomp.sh

# 3. Extract game files (already done!)
# Files are in: ./extracted/main/
```

## 📋 Common Operations

### View PCK Contents

```bash
godotpcktool -p ~/.local/share/Steam/steamapps/common/Neongarten/Neongarten.pck -a list | head -50
```

### Extract PCK

```bash
godotpcktool -p <pck-file> -a extract -o ./extracted/main
```

### Full Project Recovery (Decompile GDScript)

```bash
./tools/gdre --headless --recover=~/.local/share/Steam/steamapps/common/Neongarten/Neongarten.pck --output=./recovered
```

### View Building Data

```bash
# Extract strings from a building resource
strings ./extracted/main/.godot/exported/*/export-*-factory.res
```

## 📁 Key Locations in Extracted Files

| Path | Contains |
|------|----------|
| `structures/*.tres.remap` | Building definitions (80+ buildings) |
| `perks/*.tres.remap` | Perk definitions (43 perks) |
| `scripts/*.gdc` | Compiled GDScript (game logic) |
| `models/*.glb.import` | 3D model references |
| `scenes/*.gdshader` | Readable shader files |
| `sprites/` | UI icons and textures |
| `translations/` | Localization strings |

## 🏗️ Building Categories

| Category | Examples |
|----------|----------|
| **Residential** | apartment, penthouse, shanty |
| **Commercial** | bar, cafe, nightclub |
| **Industrial** | factory, refinery, gruel_plant |
| **Corporate** | corp_hq, incubator, lobbyist |
| **Tech** | network_junction, data_tap, hacker_shack |
| **Parks** | quick_park, large_park, laser_park |
| **Illegal** | black_market, underground_rave |
| **Civic** | plaza, civic_monument, housing_authority |

## ⚡ Perk Examples

| Perk | Effect |
|------|--------|
| `cheap_booze` | Bars gain +INCOME from Shanty Apartments |
| `corner_networks` | Network bonuses for corner placement |
| `simple_stacking` | Stacking bonuses |
| `lord_of_the_sludge` | Industrial focus |
| `double_agents` | Agent-based synergies |

## 🛠️ Modding Workflow

### Simple Asset Swap

1. Extract PCK
2. Replace asset (texture, model, sound)
3. Repack with: `godotpcktool -p modded.pck -a add -f ./modded --set-godot-version 4.3.0`
4. Backup and replace original PCK

### Balance Modification

1. Run full project recovery with gdsdecomp
2. Edit `.tres` resource files
3. Recompile with Godot 4.3
4. Repack PCK

### Script Modification

1. Decompile with gdsdecomp
2. Edit `.gd` source files
3. Test in Godot editor
4. Recompile and repack

## 📖 Documentation

- [TECHNICAL_RESEARCH.md](docs/TECHNICAL_RESEARCH.md) - Full technical details
- [GAME_ANALYSIS.md](docs/GAME_ANALYSIS.md) - Game mechanics analysis
- [ART_GUIDELINES.md](docs/ART_GUIDELINES.md) - Asset creation guide

## 🔗 Resources

- **gdsdecomp**: <https://github.com/GDRETools/gdsdecomp>
- **Godot Docs**: <https://docs.godotengine.org/>
- **Neongarten Steam**: <https://store.steampowered.com/app/3211750>
- **Discord**: <https://discord.gg/HvtvGbSwax>
