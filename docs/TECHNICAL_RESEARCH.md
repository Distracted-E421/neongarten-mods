# Neongarten - Technical Research

## Status: ✅ Engine Confirmed - Godot 4.3.0

This document tracks our technical research into Neongarten's implementation.

---

## Game Engine: CONFIRMED

### ✅ **Godot 4.3.0**

**Definitive Evidence:**
- PCK header confirms: `Pck version: 2, Godot: 4.3.0`
- `.pck` files are Godot Pack format
- `.gdc` files are Godot compiled GDScript
- `.gdshader` files in readable text format
- `.translation` files are Godot localization format
- Credits mention: "This is my first game in Godot"

### Developer Information

From translations/credits:
- **Developer**: Josh Galecki (Moonroof Studios)
- **Publisher**: Goblinz Publishing
- **Framework**: Started with Kenney's City Builder Starter Kit
- **Tools**: Asset Forge 3D modeling program
- **Collective**: Tiny Mass Games

---

## File Structure

### Game Installation

```
~/.local/share/Steam/steamapps/common/Neongarten/
├── Neongarten.exe              # Main game (61MB, PE32+ x86-64)
├── Neongarten.pck              # Main game data (358MB)
├── NeongartenPrologue.exe      # Prologue demo (71MB)
├── NeongartenPrologue.pck      # Prologue data (228MB)
├── steam_api64.dll             # Steam integration
├── Licenses.txt                # Font licenses
└── translations/               # Localization
    ├── Neongarten_translations.csv     # Master translation file
    ├── Neongarten_translations.en.translation
    ├── Neongarten_translations.de.translation
    ├── Neongarten_translations.fr.translation
    ├── Neongarten_translations.ja.translation
    ├── Neongarten_translations.ko.translation
    ├── Neongarten_translations.pl.translation
    ├── Neongarten_translations.zh_CN.translation
    └── Neongarten_translations.zh_TW.translation
```

### Extracted PCK Structure (351MB, 2,966 files)

```
extracted/main/
├── .godot/
│   ├── exported/133200997/     # Compiled resources (.res, .scn)
│   └── imported/               # Imported assets
├── fonts/                      # Font files
├── models/                     # 3D models (GLB format)
│   ├── *.glb.import           # Import configs
│   ├── coins/                 # Coin meshes
│   └── Textures/              # Model textures
├── models 2/                   # Additional models
│   ├── Coins and Cars/
│   ├── extracted meshes/
│   └── Grounds/
├── music/                      # Audio files
├── particles/                  # Particle effects
├── perks/                      # Perk definitions (43 perks)
│   └── *.tres.remap           # Perk resource refs
├── player/                     # Player data
├── scenes/
│   ├── lit_model_scenes/      # Building scenes with lights
│   ├── UI/                    # UI scenes
│   ├── *.gdshader             # Shader files (readable!)
│   └── *.tscn.remap           # Scene refs
├── scripts/                    # GDScript (compiled .gdc)
│   ├── CityScreen.gdc         # Main game logic (50KB!)
│   ├── data_map.gdc           # Game data (35KB)
│   ├── structure.gdc          # Building logic
│   ├── perk.gdc               # Perk logic
│   └── *.gd.remap             # Script refs
├── shaders/                    # Additional shaders
├── sounds/                     # Sound effects
├── sprites/                    # 2D sprites/textures
├── structures/                 # Building definitions (80+ buildings)
│   └── *.tres.remap           # Building resource refs
├── symbols/                    # Symbol resources
├── Themes/                     # UI themes
├── translations/               # Localization
├── UI art/                     # UI graphics
│   └── final perk icons/      # Perk icon PNGs
├── project.binary             # Compiled project settings
├── splash-screen.png          # Startup screen
└── Symbol.gdc                 # Symbol class
```

---

## Data Formats

### Building Resource (Structure)

**File Type**: Binary Godot Resource (.res)  
**Format**: RSRC header, binary serialized

**Properties** (extracted via strings):
```
resource_local_to_scene     # bool
resource_name               # String
script                      # res://scripts/structure.gd
scene                       # PackedScene (lit model)
image                       # Texture2D (UI icon)

# Model variants for adjacency
has_covered_model           # bool - when covered from above
show_covered_when_covered   # bool
has_up_model                # bool - top extension
show_up_when_covered        # bool
has_north_model             # bool
show_north_when_north_neighbor  # bool
has_east_model              # bool
show_east_when_east_neighbor    # bool
has_south_model             # bool
show_south_when_south_neighbor  # bool
has_west_model              # bool
show_west_when_west_neighbor    # bool

# Gameplay properties
income                      # int - base income
multiplier                  # float - income multiplier
power                       # int - power generation/consumption
amplify                     # float - amplification factor
type                        # int/enum - building type
family                      # int/enum - building family
x_size                      # int - footprint X
z_size                      # int - footprint Z
y_size                      # int - height
rarity                      # int - spawn rarity
description                 # String - internal desc
priority                    # int - spawn priority
lights_level                # int - neon light intensity
legality                    # int/enum - legal/illegal
name_key                    # String - translation key
description_key             # String - translation key
flavor_key                  # String - translation key
unlock_set_index            # int - unlock progression
has_bonus_counter           # bool - shows counter UI
```

**Example (Factory)**:
```
Script: res://scripts/structure.gd
Scene: res://scenes/lit_model_scenes/factory.tscn
Image: res://sprites/T_UI_Building_Industrial_Factory.png
Description: "An INDUSTRIAL center of production.
              Gains +1 INCOME for each INDUSTRIAL building
              in the same vertical stack."
```

### Perk Resource

**File Type**: Binary Godot Resource (.res)  
**Format**: RSRC header, binary serialized

**Properties**:
```
script          # res://scripts/perk.gd
type            # int/enum
name            # String
description     # String
rarity          # int
icon            # Texture2D
name_key        # String - translation key
description_key # String - translation key
```

**Example (Cheap Booze)**:
```
Name: "Cheap Booze"
Description: "Bars also gain +INCOME for neighboring Shanty Apartments."
Icon: res://UI art/final perk icons/c_perk_cheap_booze.png
```

### 3D Models

**Format**: GLB (Binary glTF)  
**Tool**: Blender, Asset Forge

Models are standard GLB format, easily importable into Blender:
- Located in `models/` and `models 2/`
- Naming convention: `<building_name>.glb`
- Some have variants: `*_base.glb`, `*_topped.glb`, `*_animated_*.glb`

### Shaders

**Format**: Text-based Godot shader (.gdshader)  
**Readable**: ✅ Yes!

Located in `scenes/*.gdshader`:
- `restyle_sky.gdshader` - Procedural sky with clouds
- `stylized_sky.gdshader` - Alternative sky shader

---

## Tool Chain

### Required Tools

| Tool | Purpose | Status |
|------|---------|--------|
| **godotpcktool** | PCK extraction/creation | ✅ In nixpkgs |
| **gdsdecomp** | GDScript decompilation, full project recovery | ⚠️ Download from GitHub |
| **gdtoolkit** | GDScript linting/formatting | ✅ In nixpkgs |
| **Godot 4.3** | Editor for mod creation | ✅ In nixpkgs |
| **Blender** | 3D model editing | ✅ In nixpkgs |

### Installation

```bash
# Enter dev environment
cd /home/e421/neongarten-mods
nix develop

# Download gdsdecomp (for full decompilation)
# https://github.com/GDRETools/gdsdecomp/releases
# Get: gdre_tools-*-linux.zip
```

### Common Operations

```bash
# List PCK contents
godotpcktool -p ~/.local/share/Steam/steamapps/common/Neongarten/Neongarten.pck -a list

# Extract PCK
godotpcktool -p <pck> -a extract -o ./extracted/main

# Full project recovery (requires gdsdecomp)
./gdre_tools --headless --recover=<pck>

# Extract strings from binary resource
strings ./extracted/main/.godot/exported/*/export-*-factory.res

# Hex dump resource
xxd ./extracted/main/.godot/exported/*/export-*-factory.res | head -100
```

---

## Modding Approaches

### 1. Asset Replacement (Easiest)

Replace textures, models, or sounds in a new PCK:

```bash
# 1. Extract
godotpcktool -p original.pck -a extract -o ./modded

# 2. Replace assets
cp my_texture.png ./modded/sprites/

# 3. Repack
godotpcktool -p modded.pck -a add -f ./modded --set-godot-version 4.3.0

# 4. Replace original (backup first!)
cp modded.pck ~/.local/share/Steam/steamapps/common/Neongarten/Neongarten.pck
```

### 2. Data Modification (Medium)

Modify building/perk values:

1. Use gdsdecomp to recover project
2. Edit `.tres` resource files
3. Recompile with Godot 4.3
4. Repack PCK

### 3. Script Modification (Advanced)

Modify game logic:

1. Decompile GDScript with gdsdecomp
2. Edit `.gd` source files
3. Recompile with Godot 4.3
4. Repack PCK

### 4. Mod Loader (Future)

Create a mod loading system:

1. Develop Godot addon that loads external resources
2. Create mod format specification
3. Integrate with stl-next for management

---

## Key Scripts (for decompilation)

| Script | Size | Purpose |
|--------|------|---------|
| `CityScreen.gdc` | 50KB | Main game screen, core gameplay |
| `data_map.gdc` | 35KB | Game data definitions |
| `placed_structure.gdc` | 17KB | Placed building behavior |
| `GridTileDisplay.gdc` | 16KB | Grid rendering |
| `PerkOverlayScreen.gdc` | 12KB | Perk selection UI |
| `NewGameScreen.gdc` | 12KB | New game setup |
| `structure.gdc` | 5.7KB | Building base class |
| `perk.gdc` | 1.2KB | Perk base class |

---

## Building Categories

From extracted data:

### Residential
- lame_apartment, fancy_apartment, penthouse_apartment
- shanty_apartment, home_from_work_box

### Commercial  
- bar, lame_cafe, nightclub, coffee_shop
- spiced_gruel_store, tourist_office, oxygenhaus

### Industrial
- factory, gruel_plant, refinery, plastic_mine
- battery_complex, machine_shop, printing_press

### Corporate
- corp_office, corp_hq, corp_incubator
- executive_retreat, lobbyist_offices

### Government/Civic
- housing_authority, civic_monument, plaza
- security_forces, memory_hole

### Tech
- network_junction, neural_net_weaver, data_tap
- hacker_shack, gene_splicer, spider_fab

### Parks
- quick_park, large_park, laser_park, outlet_park

### Illegal
- black_market, underground_rave, unlicensed_drug_manufactory
- hacktivist_network, mutant_refuge

### Religious/Weird
- secular_church, citadel_of_ohm, the_monad_of_i
- the_high_underseeker, conducting_choir

---

## Perk Categories

From extracted data (43 perks):

- **Income**: basic_builder, rare_boost, overcharged
- **Synergy**: cheap_booze, corner_networks, simple_stacking
- **Type Focus**: lord_of_the_sludge, corporate_center, neon_baptism
- **Special**: double_agents, secret_agents, prohibition
- **Illegal**: bribes, smugglers_run, nethacks

---

## Next Steps

### Immediate
- [x] Confirm game engine (Godot 4.3.0)
- [x] Extract PCK contents
- [x] Document file structure
- [x] Identify building/perk schemas
- [ ] Download and test gdsdecomp
- [ ] Perform full project recovery
- [ ] Document all building values
- [ ] Document all perk effects

### Short-term
- [ ] Create building value spreadsheet
- [ ] Create perk effect documentation
- [ ] Set up asset replacement workflow
- [ ] Create first balance mod (test)

### Long-term
- [ ] Develop mod loader addon
- [ ] Integrate with stl-next
- [ ] Create community mod repository
- [ ] Potential native Linux port investigation

---

## Linux Port Potential

Since Neongarten is Godot 4.3.0, a native Linux port is theoretically straightforward:

1. **Export Templates**: Godot can export to Linux natively
2. **No Native Code**: Appears to be pure GDScript (no GDExtension)
3. **Standard Dependencies**: No unusual platform requirements
4. **Current Status**: Windows-only, runs via Proton (Deck Verified)

**Approach**: If we establish good rapport with Moonroof Studios, we could potentially assist with Linux export testing.

---

*Last Updated: January 22, 2026*  
*Godot Version: 4.3.0*  
*PCK Format Version: 2*
