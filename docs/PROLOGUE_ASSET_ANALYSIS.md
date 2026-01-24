# Prologue Asset Analysis

## Overview

Neongarten was preceded by "Neongarten Prologue" - an earlier version with simpler art. The recovered project contains assets from both versions. This document analyzes how to programmatically identify and handle prologue assets.

## Asset Categories

### 1. Explicitly Prologue (`lame_*` prefix) - **6 files**

These are clearly marked with the `lame_` prefix:

| File | Type | Size | Status |
|------|------|------|--------|
| `sprites/lame_apartment.png` | Texture | 42KB | Orphaned |
| `sprites/lame_cafe.png` | Texture | 86KB | Orphaned |
| `sprites/lame_train_station.png` | Texture | 97KB | Orphaned |
| `models/lame_apartment.glb` | Model | - | Orphaned |
| `models/lame_cafe.glb` | Model | - | Orphaned |
| `models/lame_train_station.glb` | Model | - | Orphaned |

**Key Finding**: These files exist but are **not referenced** by any `.tres` structure files. The structure files named `lame_*.tres` actually reference modern assets (e.g., `lame_cafe.tres` → `coffee_shop.tscn`).

### 2. Non-Standard Sprites (No T_UI_ prefix)

The modern game uses `T_UI_Building_*.png` naming. Other sprites include:

- **Legitimate**: backgrounds, icons, coins, UI elements
- **Potentially orphaned**: building previews with old naming

### 3. Structure Inconsistencies

Some `.tres` structure files have naming mismatches:

- `structures/lame_apartment.tres` → References `T_UI_Building_Residential_BasicApartment.png`
- `structures/lame_cafe.tres` → References `T_UI_Building_Commercial_CoffeeShop.png`

This suggests the game was updated to use modern assets but kept the structure file names.

## Programmatic Detection Methods

### Method 1: Filename Pattern Matching

```python
PROLOGUE_PATTERNS = ["lame_", "prologue_", "old_", "test_", "placeholder_"]

def is_prologue_by_name(filename):
    lower = filename.lower()
    return any(lower.startswith(p) for p in PROLOGUE_PATTERNS)
```

### Method 2: File Size Heuristic (for sprites)

**Observation**: Prologue sprites are ~42-97KB, modern sprites are ~130-200KB.

```python
def is_likely_prologue_sprite(filepath, size_bytes):
    if size_bytes < 100_000:  # < 100KB
        return "likely_prologue"
    elif size_bytes > 120_000:  # > 120KB
        return "likely_modern"
    else:
        return "uncertain"
```

### Method 3: Reference Graph Analysis

Files not referenced by any `.tres`, `.tscn`, or `.gd` file are likely orphaned:

```gdscript
func is_orphaned(file: String, all_references: Dictionary) -> bool:
    return not file in all_references
```

### Method 4: Naming Convention Analysis

Modern assets follow conventions:
- Sprites: `T_UI_Building_{Category}_{Name}.png`
- Models: `scenes/lit_model_scenes/{name}.tscn`
- Structures: `structures/{name}.tres`

Prologue assets have inconsistent naming.

## Recommended Actions

### Safe to Delete (Orphaned Prologue)

The 6 `lame_*` files are confirmed orphaned and can be safely removed:

```bash
rm sprites/lame_*.png
rm models/lame_*.glb
```

### Rename/Restructure (Active but Misnamed)

The `structures/lame_*.tres` files should be renamed to match their actual content:
- `lame_apartment.tres` → `basic_apartment.tres` (already exists, check for duplicates)
- `lame_cafe.tres` → `coffee_shop.tres`
- `lame_train_station.tres` → (determine actual building)

### Manual Review Needed

Non-`T_UI_` sprites in `sprites/` directory need visual review to determine:
- Which are legitimate (UI, backgrounds, etc.)
- Which are orphaned prologue assets
- Which should be renamed

## EditorScript Tools

Use these scripts (in `tools/godot-harness/editor-scripts/`) to analyze:

1. **find_orphaned_assets.gd** - Lists all unreferenced files
2. **identify_prologue_assets.gd** - Specifically finds prologue patterns
3. **export_asset_manifest.gd** - Creates full JSON inventory

## Automation Commands

```bash
# List all prologue-pattern files
find . -name "lame_*" -o -name "prologue_*" -o -name "old_*"

# Find orphaned assets (via Godot headless)
godot-cmds find-orphans

# Full asset analysis
godot-cmds analyze-assets
```

## File Size Statistics

| Category | Size Range | Count |
|----------|------------|-------|
| Prologue sprites | 42-97 KB | 3 |
| Modern T_UI_ sprites | 130-200 KB | 50+ |
| Backgrounds | 200-500 KB | 8 |
| Icons | 5-50 KB | 20+ |

## Conclusion

The prologue assets are:
1. **Easy to identify**: `lame_*` prefix
2. **Safe to remove**: All are orphaned (unreferenced)
3. **Low impact**: Only 6 files

The misnamed structure files (`structures/lame_*.tres`) should be investigated to avoid duplicates with properly-named versions.

