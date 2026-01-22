# Neongarten - Technical Research

## Status: 🔬 Active Investigation

This document tracks our technical research into Neongarten's implementation.

---

## Game Engine Investigation

### Hypothesis: Unity

**Evidence For:**
- Minimalist 3D graphics style common in Unity indie games
- Windows-only native with Proton support (common Unity pattern)
- DirectX 11 / OpenGL 3.3 requirements (Unity typical)
- Goblinz Publishing has published Unity games before

**Evidence Against:**
- No definitive proof yet
- Could also be Godot or custom engine

### How to Confirm

```bash
# Method 1: Check for Unity files in game directory
ls -la ~/.steam/steam/steamapps/common/Neongarten/
# Look for: UnityPlayer.dll, unity_default_resources, globalgamemanagers

# Method 2: Check executable metadata
file ~/.steam/steam/steamapps/common/Neongarten/*.exe

# Method 3: Process analysis while running
lsof -p $(pgrep -f Neongarten) | grep -E "mono|unity"
```

### Research Tasks

- [ ] Install game and examine file structure
- [ ] Check Steam depot files for engine hints
- [ ] Look for log files that reveal engine
- [ ] Check community discussions for dev statements

---

## File Structure Analysis

### Expected Locations (Steam + Proton)

```
# Game installation
~/.steam/steam/steamapps/common/Neongarten/

# Proton prefix (save data, configs)
~/.steam/steam/steamapps/compatdata/3211750/pfx/

# Steam cloud saves
~/.steam/steam/userdata/<user_id>/3211750/
```

### File Types to Investigate

| Extension | Possible Content | Priority |
|-----------|------------------|----------|
| `.assets` | Unity asset bundles | High |
| `.json` | Config/data files | High |
| `.xml` | Config files | Medium |
| `.dat` | Binary data | Medium |
| `.dll` | C# assemblies (if Unity) | High |
| `.resources` | Unity resources | Medium |

---

## Modding Approaches by Engine

### If Unity

#### BepInEx (Recommended)
```bash
# BepInEx is the standard Unity modding framework
# Provides:
# - Plugin loading
# - Harmony patching
# - Config system
# - Logging

# Installation:
# 1. Download BepInEx for Unity
# 2. Extract to game folder
# 3. Run game once to generate configs
# 4. Place plugins in BepInEx/plugins/
```

#### Asset Bundle Mods
```csharp
// Replace textures/models
AssetBundle bundle = AssetBundle.LoadFromFile("mods/custom.bundle");
GameObject prefab = bundle.LoadAsset<GameObject>("NewBuilding");
```

#### Harmony Patching
```csharp
// Modify game behavior
[HarmonyPatch(typeof(Building), "CalculateIncome")]
class IncomePatch {
    static void Postfix(ref int __result) {
        __result *= 2; // Double all income
    }
}
```

### If Godot

#### GDScript Mods
```gdscript
# Godot allows runtime loading of scenes/scripts
var mod = load("res://mods/my_mod.gd")
mod.apply()
```

#### PCK File Replacement
```bash
# Export custom .pck files
# Replace or supplement game data
```

### If Custom Engine

- Reverse engineering required
- Binary patching likely needed
- Asset formats must be decoded
- Significantly more work

---

## Asset Formats

### 3D Models (Unknown)

**Possible Formats:**
- `.fbx` - Standard Unity import
- `.gltf/.glb` - Modern open format
- `.obj` - Simple meshes
- Proprietary bundle format

**For Evie's Workflow:**
- Blender → FBX export likely safest
- May need to match existing rig/scale
- UV mapping must match texture format

### Textures (Unknown)

**Possible Formats:**
- PNG/TGA - Standard (likely)
- DDS - DirectX compressed
- Unity's proprietary format

**Considerations:**
- Power-of-two dimensions?
- Mipmaps required?
- Normal maps for lighting?

### Audio (Unknown)

**Possible Formats:**
- `.ogg` - Common for games
- `.wav` - Uncompressed
- `.mp3` - Less common in games

---

## Data Files Research

### Building Definitions

**Expected Structure (Speculation):**
```json
{
  "buildings": [
    {
      "id": "basic_apartment",
      "name": "Basic Apartment",
      "category": "residential",
      "base_income": 10,
      "synergies": [
        {"with": "park", "bonus": 5},
        {"with": "penthouse", "bonus": -2}
      ],
      "model": "models/apartment_basic.fbx",
      "texture": "textures/apartment_basic.png",
      "unlock_day": 1
    }
  ]
}
```

### Perk Definitions

**Expected Structure (Speculation):**
```json
{
  "perks": [
    {
      "id": "income_boost_residential",
      "name": "Real Estate Mogul",
      "description": "Residential buildings earn 20% more",
      "effect": {
        "type": "income_multiplier",
        "target": "residential",
        "value": 1.2
      },
      "unlock_condition": "reach_day_30"
    }
  ]
}
```

---

## Reverse Engineering Tools

### General

```bash
# File identification
file <unknown_file>
xxd <binary_file> | head -50

# String extraction
strings <binary_file> | grep -i "unity\|godot\|building"
```

### Unity Specific

```bash
# AssetStudio - Unity asset viewer
# https://github.com/Perfare/AssetStudio

# UABE - Unity Asset Bundle Extractor
# https://github.com/SeriousCache/UABE

# dnSpy - C# decompiler (for DLLs)
# https://github.com/dnSpy/dnSpy
```

### Godot Specific

```bash
# Godot RE Tools
# https://github.com/bruvzg/gdsdecomp

# Extract .pck files
godot --export-pack
```

---

## Testing Environment

### Proton Setup for Modding

```bash
# Find game's Proton prefix
PROTON_PREFIX="$HOME/.steam/steam/steamapps/compatdata/3211750/pfx"

# Run commands in Proton environment
WINEPREFIX="$PROTON_PREFIX" wine explorer /desktop=shell

# Check logs
cat "$PROTON_PREFIX/drive_c/users/steamuser/AppData/LocalLow/*/Player.log"
```

### Development Workflow

```
1. Backup original game files
2. Make modification
3. Test via Steam launch
4. Check logs for errors
5. Iterate
```

---

## Known Issues & Bugs

From Steam Community:

### AMD Graphics Issues
- Texture flashing on AMD GPUs
- Dev released special build (Sep 2025)
- Suggests OpenGL/DirectX rendering path

### Controller Support
- Native controller incomplete
- Steam Input workaround exists
- Suggests input system could be modded

---

## Next Steps

### Immediate
1. [ ] Install game on Obsidian
2. [ ] Examine file structure
3. [ ] Identify engine definitively
4. [ ] Extract and analyze asset formats

### Short-term
1. [ ] Set up modding framework (BepInEx if Unity)
2. [ ] Create "Hello World" mod
3. [ ] Document data file formats
4. [ ] Create asset pipeline for Evie

### Long-term
1. [ ] Build mod loader/manager
2. [ ] Create content creation tools
3. [ ] Establish mod distribution method

---

*Last Updated: January 2026*

