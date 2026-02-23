# Neongarten Mods

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Godot](https://img.shields.io/badge/Godot-4.3-blue.svg)](https://godotengine.org/)
[![NixOS](https://img.shields.io/badge/NixOS-flake-blue.svg)](flake.nix)

Community modding toolkit for **Neongarten** - a minimalist cyberpunk city builder by Moonroof Studios.

## 🎮 About Neongarten

| | |
|---|---|
| **Genre** | Turn-based Strategy / City Builder / Roguelite |
| **Engine** | **Godot 4.3.0** ✅ |
| **Aesthetic** | Minimalist Cyberpunk / Neon |
| **Developer** | Josh Galecki (Moonroof Studios) |
| **Publisher** | Goblinz Publishing |
| **Steam** | [store.steampowered.com/app/3211750](https://store.steampowered.com/app/3211750/Neongarten/) |
| **Discord** | [discord.gg/HvtvGbSwax](https://discord.gg/HvtvGbSwax) |

## 🚀 Quick Start

```bash
# Enter development environment
cd neongarten-mods
nix develop

# Install gdsdecomp (one-time)
./tools/setup-gdsdecomp.sh

# See QUICKSTART.md for full workflow
```

## 📁 Project Structure

```
neongarten-mods/
├── QUICKSTART.md           # Quick reference guide
├── README.md               # This file
├── flake.nix               # Nix development environment
├── docs/
│   ├── GAME_ANALYSIS.md    # Game mechanics deep dive
│   ├── TECHNICAL_RESEARCH.md # Engine & formats (Godot 4.3.0)
│   └── ART_GUIDELINES.md   # Asset creation guide for Evie
├── tools/
│   ├── setup-gdsdecomp.sh  # gdsdecomp installer
│   ├── extractor/          # Asset extraction tools
│   └── packer/             # Asset packing tools
├── mods/
│   ├── gameplay/           # Balance & gameplay mods
│   ├── content/            # New content mods
│   └── visual/             # Visual & aesthetic mods
├── assets/
│   ├── models/             # 3D models (Evie's work)
│   ├── textures/           # Texture files
│   └── reference/          # Reference images
└── extracted/              # Extracted game files (gitignored)
```

## 🛠️ Technical Stack

| Tool | Purpose | Source |
|------|---------|--------|
| **Godot 4** | Game engine / Editor | nixpkgs |
| **godotpcktool** | PCK extraction/creation | nixpkgs |
| **gdsdecomp** | GDScript decompilation | [GitHub](https://github.com/GDRETools/gdsdecomp) |
| **gdtoolkit** | GDScript linting/formatting | nixpkgs |
| **Blender** | 3D model editing (GLB) | nixpkgs |

## 📊 Game Data

### Buildings (80+)

| Category | Examples |
|----------|----------|
| Residential | apartment, penthouse, shanty |
| Commercial | bar, cafe, nightclub |
| Industrial | factory, refinery, gruel_plant |
| Corporate | corp_hq, incubator, lobbyist |
| Tech | network_junction, data_tap, hacker_shack |
| Parks | quick_park, large_park, laser_park |
| Illegal | black_market, underground_rave |
| Civic | plaza, civic_monument |

### Perks (43)

Categories include income multipliers, synergy enhancers, type focus, and special mechanics.

### Game Modes

| Mode | Grid Size | Description |
|------|-----------|-------------|
| Stack | 4 x 4 x 8 | The original |
| Cube | 5 x 5 x 5 | The layer cake |
| Needle | 3 x 3 x 14 | The stiletto |

## 🎯 Modding Goals

### Phase 1: Research ✅
- [x] Identify game engine (Godot 4.3.0)
- [x] Extract and document file structure
- [x] Document building/perk schemas
- [x] Set up development environment

### Phase 2: Simple Mods
- [ ] Balance tweaks (building values)
- [ ] Texture replacements
- [ ] Sound replacements
- [ ] Perk adjustments

### Phase 3: Content Mods
- [ ] New building types
- [ ] New perks
- [ ] New game modes

### Phase 4: Advanced
- [ ] Mod loader system
- [ ] stl-next integration
- [ ] Community mod repository

## 👥 Team

- **e421** - Programming, modding infrastructure, game design
- **Evie** - 3D modeling, textures, visual design (Wacom tablet)

## 🔧 Development

### Prerequisites

- NixOS or Nix package manager
- Git
- ~500MB disk space for extracted files

### Environment

```bash
# Uses Nix flake for reproducible environment
nix develop

# Available tools:
# - godot (Godot 4 editor)
# - godotpcktool (PCK tools)
# - gdformat/gdlint (GDScript tools)
# - blender (3D modeling)
# - steam-run (game launching)
```

### Workflow

1. **Extract**: Use godotpcktool to extract PCK
2. **Analyze**: Study structure and find modding targets
3. **Modify**: Edit resources/scripts
4. **Test**: Run modified PCK via Steam
5. **Package**: Create distributable mod

## 📝 License

TBD - Likely MIT or Apache 2.0 for tooling.

**Note**: This is an unofficial fan project. We are not affiliated with Moonroof Studios or Goblinz Publishing. Game assets remain property of their respective owners.

---

*Last Updated: January 22, 2026*
