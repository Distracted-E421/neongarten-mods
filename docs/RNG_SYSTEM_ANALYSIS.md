# Neongarten RNG System Analysis

## Overview

This document details the Random Number Generation systems in Neongarten,
based on decompiled source code analysis from Godot 4.3.0.

---

## Building Selection RNG

### Location: `CityScreen.gd::get_three_building_choices()`

### Algorithm

```gdscript
# 1. Start with empty choices array
var choices: Array[int] = []

# 2. If BasicBuilder perk active, guarantee Apartment (index 3)
if map.has_perk(Perk.Types.BasicBuilder) && not has_ice_and_basic_apartment:
    choices.append(3)  # Apartment always first choice

# 3. Build weighted pool based on rarity
var possibilities: Array[int] = []
for each building:
    if locked or demo_locked or attract_mode_restricted:
        continue
    if captain_ice_challenge and already_placed:
        continue
    
    match rarity:
        Common:    add 8 chances (base)
        Uncommon:  add 4 chances (base)
        Rare:      add 1 chance  (base)

# 4. Apply perk modifiers to weights
if SolarPunk && family == Park:     +1 chance (all rarities)
if UncommonBuildings && Uncommon:   +2 chances
if RareBuildings && Rare:           +1 chance
if IAmLegion && HackerShack:        +3 chances (+2 more if UncommonBuildings)
if SmugglersRun && BlackMarket:     +3 chances (+2 more if UncommonBuildings)
if ThereIsOnlyWar && CorpWarMemorial: +3 chances (+2 more if UncommonBuildings)

# 5. Shuffle pool and pick 3 unique buildings
possibilities.shuffle()
for i in range(possibilities.size()):
    if not choices.has(possibleIndex):
        choices.append(possibleIndex)
    if choices.size() == 3:
        break

# 6. Apply hack effects (freeze/delay)
for i in range(3):
    if hack.frozen && hack.active:
        choices[i] = hack.structure_index  # Override with frozen building
    elif hack.delayed && hack.active && delay_expired:
        choices[i] = hack.structure_index  # Insert delayed building
```

### Base Weights (Vanilla)

| Rarity | Base Chances | With UncommonBuildings | With RareBuildings |
|--------|--------------|------------------------|-------------------|
| Common | 8 | 8 | 8 |
| Uncommon | 4 | 6 | 4 |
| Rare | 1 | 1 | 2 |

### Probability Distribution (Vanilla)

Given a typical pool (e.g., 30 Common, 20 Uncommon, 10 Rare buildings):

```
Common pool:   30 buildings × 8 = 240 chances
Uncommon pool: 20 buildings × 4 = 80 chances
Rare pool:     10 buildings × 1 = 10 chances
Total:                           330 chances

P(Common)   = 240/330 = 72.7%
P(Uncommon) = 80/330  = 24.2%
P(Rare)     = 10/330  = 3.0%
```

---

## Perk Selection RNG

### Location: `CityScreen.gd::get_three_perk_choices()`

### Algorithm

```gdscript
var choices: Array[int] = []
var possibilities: Array[int] = []

for each perk:
    if already_chosen or locked:
        continue
    
    match rarity:
        Common:   add 3 chances
        Uncommon: add 1 chance

possibilities.shuffle()
# Pick 3 unique perks
```

### Perk Weights

| Rarity | Chances |
|--------|---------|
| Common | 3 |
| Uncommon | 1 |

---

## Shanty Apartment Placement RNG

### Location: `CityScreen.gd::add_shanty_apartments()`

Every rent period (on Normal/Dystopian difficulty), 3 shanty apartments are added:

```gdscript
# For each of 3 shanties:
var cell = Vector3i(
    randi_range(0, columns - 1),  # Random X
    0,                             # Start at ground
    randi_range(0, rows - 1)       # Random Z
)

# Stack up until finding empty space
while map.has_structure_at(cell):
    cell.y += 1

# Random facing (rotation)
var facing_roll = randi_range(0, 3)
```

---

## Other RNG Elements

### Random Building Facing
```gdscript
func random_facing() -> PlacedStructure.Facings:
    var facing_roll = randi_range(0, 3)
    match facing_roll:
        0: return NE
        1: return SE
        2: return SW
        _: return NW  # 3
```

### Music Randomization
```gdscript
func play_random_song():
    var song_index = randi_range(0, songs.size() - 1)
    while song_index == current_song_index:
        song_index = randi_range(0, songs.size() - 1)
```

### Day/Night Light Toggle Timing
```gdscript
var random = RandomNumberGenerator.new()
for struct in structures:
    toggle_lights_for(on, struct, random.randf_range(0, 1))
```

---

## Moddable RNG Parameters

### High-Priority Targets for Slider Mod

| Parameter | Current Value | Suggested Range | Impact |
|-----------|---------------|-----------------|--------|
| Common weight | 8 | 1-20 | Building frequency |
| Uncommon weight | 4 | 1-15 | Building frequency |
| Rare weight | 1 | 1-10 | Building frequency |
| Perk Common weight | 3 | 1-10 | Perk frequency |
| Perk Uncommon weight | 1 | 1-10 | Perk frequency |
| Shanty count | 3 | 0-10 | Difficulty |
| SolarPunk bonus | 1 | 0-5 | Perk effectiveness |
| IAmLegion bonus | 3 | 0-10 | Perk effectiveness |

### Secondary Targets

| Parameter | Description |
|-----------|-------------|
| Building pool size | How many choices in slot machine |
| Reroll count (start) | Initial rerolls per game |
| Hack count (start) | Initial hacks per game |
| Challenge tag modifiers | Black ICE challenge effects |

---

## Implementation Strategy

### Option A: PCK Override (Simplest)

1. Modify `CityScreen.gd` with configurable constants
2. Create config file reader at game start
3. Pack modified scripts into override PCK
4. Load override PCK before main PCK

### Option B: GDExtension (Most Powerful)

1. Create GDExtension that hooks into rng functions
2. Expose configuration via in-game UI
3. Save/load profiles to user directory

### Option C: Memory Patching (Advanced)

1. Locate rng weight constants in memory
2. Create runtime patcher to modify values
3. Create external config UI (stl-next integration)

---

## Profile System Design

```json
{
  "profile_name": "Rare Hunter",
  "version": "1.0",
  "building_weights": {
    "common": 4,
    "uncommon": 6,
    "rare": 5
  },
  "perk_weights": {
    "common": 2,
    "uncommon": 3
  },
  "difficulty_modifiers": {
    "shanty_count": 2,
    "starting_rerolls": 5
  },
  "perk_bonuses": {
    "solar_punk_extra": 2,
    "i_am_legion_extra": 5
  }
}
```

---

## Files to Modify

| File | Purpose | Priority |
|------|---------|----------|
| `scripts/CityScreen.gd` | Main building/perk selection | HIGH |
| `scripts/singleton_info.gd` | Game configuration | MEDIUM |
| `scripts/data_map.gd` | Game state (rerolls, hacks) | MEDIUM |
| `scripts/taxman.gd` | Income/rent calculations | LOW |

---

## Testing Considerations

1. **Seed Control**: Add optional RNG seed for reproducibility
2. **Statistics**: Track actual distribution vs expected
3. **Edge Cases**: Test with extreme weights (0, max)
4. **Save Compatibility**: Ensure profiles don't break saves

---

*Document generated from decompiled Neongarten v1.0 source analysis*

