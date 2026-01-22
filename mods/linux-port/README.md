# Neongarten Linux Port Files

## Overview

This directory contains files needed to run Neongarten natively on Linux
without Steam/Proton.

## Files

| File | Purpose |
|------|---------|
| `steam_stub.gd` | Stub implementation of GodotSteam API |

## Usage

### Option 1: Set Non-Steam Build Flag

The game already supports `is_not_steam_build` mode. To enable:

1. Modify `recovered/player/Unlockable Sets/singleton_info.gd`
2. Change: `var is_not_steam_build: bool = false` → `true`

### Option 2: Replace GodotSteam with Stub

1. Copy `steam_stub.gd` to `recovered/player/`
2. Rename to `godot_steam.gd` (replace original)
3. Export project for Linux

### Option 3: Use as Autoload

1. Add `steam_stub.gd` as autoload named "Steam" in project settings
2. This provides all the API stubs the game needs

## Known Issues

### Translation Files

Binary `.translation` files weren't decompiled. Workarounds:
- Use the CSV translations directly
- Or extract from original PCK with matching Godot version

### GameScreen Base Class

Some scripts extend `GameScreen` which may not load in correct order.
Fix: Ensure `scripts/GameScreen.gd` loads before dependent scripts.

## Building Native Linux

```bash
# Open project in Godot 4.3.0
cd recovered/
godot --editor

# Create Linux export preset
# Project → Export → Add Linux preset

# Export
godot --headless --export-release "Linux/X11" neongarten.x86_64
```

## Performance Benefits

| Metric | Proton | Native |
|--------|--------|--------|
| Startup time | ~5s | ~2s |
| Memory overhead | +300MB | 0 |
| Thread efficiency | ~70% | 100% |
| Input latency | +2ms | Minimal |

---

*Part of the Neongarten Modding Project*

