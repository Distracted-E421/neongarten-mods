# Neongarten Art Guidelines

## For Evie - 3D Modeling & Texturing Guide

This document provides guidelines for creating custom assets for Neongarten mods.

---

## Visual Style Reference

### Aesthetic: Minimalist Cyberpunk

Neongarten's visual style combines:
- **Low-poly/minimalist geometry** - Clean shapes, few polygons
- **Bright neon accents** - Cyan, magenta, yellow, green
- **Dark base colors** - Blacks, dark grays, deep blues
- **Glowing elements** - Emissive materials for "lit" effect
- **Isometric clarity** - Readable from isometric camera angle

### Color Palette

**CONFIRMED FROM DECOMPILED SOURCE (main.tscn)**

```
┌─────────────────────────────────────────────────────┐
│ ⚠️  OFFICIAL FACTION/LEGALITY COLORS               │
│     (These are the EXACT colors from the game)      │
├─────────────────────────────────────────────────────┤
│                                                     │
│ 🏛️  CORP (Corporate)                                │
│     #BC9A51 - Golden/Amber                          │
│     Color(0.737, 0.604, 0.318, 1)                   │
│     Used: Corp Office, Corp HQ, Recruiter, etc.     │
│                                                     │
│ 🔴 ILLEGAL (Criminal)                               │
│     #B53445 - Deep Red                              │
│     Color(0.710, 0.204, 0.271, 1)                   │
│     Used: Hacker Shack, Black Market, Wetware, etc. │
│                                                     │
│ 🏢 GOVT (Government)                                │
│     #4480B2 - Official Blue                         │
│     Color(0.267, 0.502, 0.698, 1)                   │
│     Used: Civic Commons, Ministry, Bureaucrat, etc. │
│                                                     │
│ ⚡ VOLT (Electrical Cult)                           │
│     #81A770 - Electric Green                        │
│     Color(0.506, 0.655, 0.439, 1)                   │
│     Used: House of Volt, Battery Complex, etc.      │
│                                                     │
│ 🔘 NEUTRAL (Legal/Normal)                           │
│     #887EA3 - Muted Purple                          │
│     Color(0.533, 0.494, 0.639, 1)                   │
│     Used: Apartment, Coffee Shop, Bar, Factory, etc.│
│                                                     │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ FAMILY COLORS (Building Categories)                 │
├─────────────────────────────────────────────────────┤
│ Residential: #56b1FF (Cyan-Blue) - from UI          │
│ Commercial:  #56b1FF (same as residential in UI)    │
│ Industrial:  #56b1FF (same in UI, warmer in models) │
│ Park:        #56b1FF (greenish in models)           │
├─────────────────────────────────────────────────────┤
│ Note: Family colors mainly affect UI labels.        │
│ Model colors should follow FACTION colors above.    │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ LIGHTS LEVELS (Emissive Intensity)                  │
├─────────────────────────────────────────────────────┤
│ Unlit:   No emissive elements (base building)       │
│ Lights:  Subtle glow (windows, small signs)         │
│ LIT:     Strong emissive (neon signs, big effects)  │
├─────────────────────────────────────────────────────┤
│ UI Color: #fcbf5e (Orange-Yellow) for lights info   │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ BASE COLORS (Building Materials)                    │
├─────────────────────────────────────────────────────┤
│ Dark Gray:    #1a1a2e                               │
│ Medium Gray:  #2d2d44                               │
│ Concrete:     #3d3d5c                               │
│ Metal:        #4a4a6a                               │
├─────────────────────────────────────────────────────┤
│ NEON ACCENTS (Glowing elements)                     │
├─────────────────────────────────────────────────────┤
│ Cyan:         #00fff0                               │
│ Magenta:      #ff00ff                               │
│ Yellow:       #ffff00                               │
│ Green (Neon): #15ea79 (Building names use this)     │
│ Orange:       #ff8800                               │
│ Blue:         #0088ff                               │
└─────────────────────────────────────────────────────┘
```

---

## Model Specifications

### Geometry Guidelines

| Aspect | Guideline | Why |
|--------|-----------|-----|
| Poly Count | 200-500 triangles | Matches existing style |
| Style | Hard surface, no organic curves | Architectural feel |
| Scale | 1 unit = 1 game tile | Grid alignment |
| Origin | Bottom center | Placement system |
| Orientation | Z-up, facing -Y | Unity standard |

### Building Size Reference

```
            ┌──────────────────────────────────────┐
            │         BUILDING HEIGHT GUIDE        │
            ├──────────────────────────────────────┤
            │                                      │
            │    ┌─┐                               │
            │    │ │ 4 units - Skyscraper          │
            │    │ │                               │
            │    ├─┤                               │
            │    │ │ 3 units - Corporate/Tower     │
            │    │ │                               │
            │    ├─┤                               │
            │    │ │ 2 units - Apartment/Factory   │
            │    ├─┤                               │
            │    │ │ 1 unit  - Basic/Shop          │
            │    └─┘                               │
            │    ───  0      - Park/Plaza (ground) │
            └──────────────────────────────────────┘
```

### Footprint Sizes

| Size | Dimensions | Examples |
|------|------------|----------|
| Small | 1x1 tile | Basic apartment, shop |
| Medium | 2x1 tile | Factory, mall |
| Large | 2x2 tile | Corporate HQ, plaza |

---

## Texture Specifications

### Format & Resolution

| Type | Resolution | Format | Notes |
|------|------------|--------|-------|
| Diffuse/Albedo | 256x256 | PNG | Base color + alpha |
| Emissive | 256x256 | PNG | Glow areas (black = no glow) |
| Normal | 256x256 | PNG | Optional - adds detail |

### UV Layout Tips

```
┌────────────────────────────────────────┐
│           UV LAYOUT BEST PRACTICES     │
├────────────────────────────────────────┤
│                                        │
│  1. Use full UV space (0-1)            │
│                                        │
│  ┌─────────┬─────────┐                 │
│  │  ROOF   │  WALLS  │                 │
│  │         │         │                 │
│  ├─────────┼─────────┤                 │
│  │  NEON   │ DETAILS │                 │
│  │ STRIPS  │         │                 │
│  └─────────┴─────────┘                 │
│                                        │
│  2. Keep similar elements together     │
│  3. Align neon strips for easy editing │
│  4. Leave margin for texture bleeding  │
│                                        │
└────────────────────────────────────────┘
```

---

## Blender Workflow

### Recommended Setup

```
File > New > General

Units: Metric, 1.0 scale
Grid: 1 unit spacing

Viewport Settings:
- Matcap shading for modeling
- Material preview for texturing
- Rendered view for final check
```

### Export Settings (FBX)

```
Export FBX:
├── Selected Objects: ✓
├── Scale: 1.0
├── Apply Modifiers: ✓
├── Forward: -Y Forward
├── Up: Z Up
└── Geometry:
    ├── Smoothing: Edge
    ├── Export Subdivision: Off
    └── Triangulate: ✓
```

### File Naming Convention

```
<category>_<name>_<variant>.fbx

Examples:
residential_apartment_basic.fbx
residential_apartment_luxury.fbx
commercial_shop_neon.fbx
industrial_factory_large.fbx
```

---

## Creating Neon Effects

### Method 1: Separate Geometry

Create separate meshes for neon strips:

```
building_body.fbx     - Main structure (regular material)
building_neon.fbx     - Neon elements (emissive material)
```

### Method 2: Emissive Map

Use an emissive texture map:

```
1. Model with neon areas on specific UV islands
2. Create diffuse texture (base colors)
3. Create emissive texture (white = glow, black = no glow)
4. Adjust emissive color/intensity in engine
```

### Neon Strip Tips

- **Width**: ~0.05 units (thin strips look better)
- **Placement**: Edges of buildings, windows, signs
- **Animation**: Consider which parts pulse/flicker
- **Color coding**: Match building category colors

---

## Reference Sheet Template

For each building, create a reference sheet:

```
┌─────────────────────────────────────────────────────┐
│ BUILDING: [Name]                                    │
├─────────────────────────────────────────────────────┤
│                                                     │
│  [Front View]    [Side View]    [Top View]          │
│                                                     │
│  [Isometric]     [Night Mode]   [Wireframe]         │
│                                                     │
├─────────────────────────────────────────────────────┤
│ Category: [Residential/Commercial/etc]              │
│ Size: [1x1/2x1/2x2]                                 │
│ Height: [1-4 units]                                 │
│ Poly Count: [target]                                │
│ Neon Colors: [list]                                 │
│ Special Features: [notes]                           │
└─────────────────────────────────────────────────────┘
```

---

## Asset Checklist

Before submitting an asset:

- [ ] Correct scale (matches grid)
- [ ] Origin at bottom center
- [ ] Clean mesh (no doubles, normals correct)
- [ ] Poly count within limits
- [ ] UVs properly laid out
- [ ] Textures correct resolution
- [ ] Emissive map created (if needed)
- [ ] FBX exported with correct settings
- [ ] Named according to convention
- [ ] Reference images included

---

## Tools

### Recommended Software

| Tool | Purpose | Notes |
|------|---------|-------|
| **Blender** | 3D modeling | Free, full-featured |
| **GIMP/Krita** | Texturing | Free alternatives to Photoshop |
| **PureRef** | Reference boards | Free reference collector |
| **AssetStudio** | Extract game assets | For reference (Unity) |

### Wacom Tablet Tips

- Use tablet for texturing (pressure sensitivity)
- Mouse may be better for precise modeling
- Set up express keys for common Blender shortcuts

---

## Communication

### File Sharing

Place completed assets in:
```
neongarten-mods/assets/models/<category>/
neongarten-mods/assets/textures/<category>/
```

### Feedback Format

```markdown
## Asset Review: [filename]

### Looks Good
- [positive feedback]

### Needs Adjustment
- [specific change needed]

### Questions
- [any clarifications needed]
```

---

*These guidelines will be updated as we learn more about the game's actual asset formats!*

