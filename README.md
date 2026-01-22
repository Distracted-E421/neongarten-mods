# Neongarten Mods

Community modding toolkit for **Neongarten** - a minimalist cyberpunk city builder by Moonroof Studios.

## 🎮 About Neongarten

- **Genre**: Turn-based Strategy / City Builder / Roguelite
- **Aesthetic**: Minimalist Cyberpunk / Neon
- **Inspirations**: ISLANDERS + Luck Be a Landlord
- **Developer**: Moonroof Studios
- **Publisher**: Goblinz Publishing
- **Steam**: [store.steampowered.com/app/3211750](https://store.steampowered.com/app/3211750/Neongarten/)
- **Discord**: [discord.gg/HvtvGbSwax](https://discord.gg/HvtvGbSwax)

## 🎯 Project Goals

This project aims to extend Neongarten with community mods focused on:

### Gameplay Mods
- **Larger maps** - Extended grid sizes for longer sessions
- **New tiles/buildings** - More structure variety and synergies
- **Faction-focused modes** - Heavy weighting toward specific building types
- **Balance adjustments** - Community-driven tuning
- **Endless mode** - Continue playing after reaching tower goals

### Content Mods
- **New game mechanics** - Fresh ways to score and progress
- **Story elements** - Lore expansion and narrative content
- **Challenge modes** - Themed setups with specific constraints
- **Achievement expansion** - New goals to chase

### Visual Mods
- **Custom building models** - New 3D assets for buildings
- **Texture packs** - Alternative visual themes
- **UI enhancements** - Quality of life improvements
- **Day/night cycle expansion** - More neon!

## 📊 Game Analysis

### What Makes Neongarten Good

1. **Elegant Simplicity** - Easy to understand, hard to master
2. **Satisfying Synergies** - Building combos feel organic (parks → rent, industry → industry)
3. **Perfect Session Length** - 10-15 minutes per run
4. **Aesthetic Cohesion** - Cyberpunk neon visuals are consistent and charming
5. **Roguelite Progression** - Unlocks keep you coming back

### Community Feedback (from Steam)

**Wants:**
- Endless/ongoing mode after completing tower
- Zoom out further (especially on wide monitors)
- Focus/challenge modes (industry, corporate, illegal emphasis)
- More substantial day/night cycle mechanics
- Better controller support
- Keyboard pan controls

**Pain Points:**
- Progression limited after unlocks
- Randomness can feel punishing
- Some achievements very difficult (Penthouse, Plaza)
- AMD graphics card texture issues

## 🔧 Technical Research

> ⚠️ **Research in Progress** - We're investigating the game's technical stack

### Game Engine
- **TBD** - Likely Unity or Godot based on the aesthetics and platform support
- Runs on Windows via Proton on Linux
- Steam Deck Playable

### File Formats
- **Models**: TBD
- **Textures**: TBD
- **Data Files**: TBD

### Modding Approach
- **TBD** - Reverse engineering needed to determine best approach
- May involve:
  - Asset replacement
  - Data file editing
  - Code injection
  - BepInEx/MelonLoader (if Unity)

## 📁 Project Structure

```
neongarten-mods/
├── README.md               # This file
├── docs/
│   ├── GAME_ANALYSIS.md    # Deep dive into game mechanics
│   ├── TECHNICAL_RESEARCH.md # Engine/format research
│   └── ART_GUIDELINES.md   # Guidelines for Evie's art assets
├── mods/
│   ├── gameplay/           # Gameplay modification mods
│   ├── content/            # New content mods
│   └── visual/             # Visual/aesthetic mods
├── tools/
│   ├── extractor/          # Asset extraction tools
│   └── packer/             # Asset packing tools
├── assets/
│   ├── models/             # 3D models (Evie's work)
│   ├── textures/           # Texture files
│   └── reference/          # Reference images from game
└── .cursor/
    └── rules/              # AI agent configuration
```

## 👥 Team

- **e421** - Programming, modding infrastructure, game design
- **Evie** - 3D modeling, textures, visual design (Wacom tablet artist)

## 🚀 Getting Started

### Prerequisites

```bash
# Nix development environment (recommended)
nix develop

# Or manual setup
# TBD based on technical research
```

### Installation

```bash
git clone https://github.com/Distracted-E421/neongarten-mods.git
cd neongarten-mods
```

## 📝 License

TBD - Likely MIT or Apache 2.0 for the tooling, with assets following game's modding terms.

## 🙏 Acknowledgments

- **Moonroof Studios** - For creating Neongarten
- **Goblinz Publishing** - For publishing and supporting the game
- The Neongarten Discord community for feedback and ideas

---

*This is an unofficial fan project. We are not affiliated with Moonroof Studios or Goblinz Publishing.*

