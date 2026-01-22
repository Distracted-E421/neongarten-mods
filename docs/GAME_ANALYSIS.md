# Neongarten - Deep Game Analysis

## Overview

**Neongarten** is a turn-based strategy city builder that combines the spatial puzzle aspects of **ISLANDERS** with the roguelite progression of **Luck Be a Landlord**. Released April 22, 2025 by Moonroof Studios.

---

## Core Game Loop

```
┌─────────────────────────────────────────────────────────────┐
│                       TURN STRUCTURE                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. OFFER PHASE                                             │
│     ├── Receive 3 building options                          │
│     ├── Option to reroll (limited uses)                     │
│     └── Must place one building                             │
│                                                             │
│  2. PLACEMENT PHASE                                         │
│     ├── Select building from hand                           │
│     ├── Choose grid position                                │
│     ├── Preview synergy bonuses                             │
│     └── Confirm placement                                   │
│                                                             │
│  3. SCORING PHASE                                           │
│     ├── Calculate base income                               │
│     ├── Apply adjacency bonuses                             │
│     ├── Apply perk multipliers                              │
│     └── Update total score                                  │
│                                                             │
│  4. PROGRESSION PHASE                                       │
│     ├── Check if tower threshold met                        │
│     ├── Unlock new building types                           │
│     └── Possibly offer perk selection                       │
│                                                             │
│  5. NIGHT PHASE (Visual)                                    │
│     ├── Neon lights activate                                │
│     └── "LIT" buildings highlighted                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Building Categories

### Residential
| Building | Base Value | Synergies | Notes |
|----------|------------|-----------|-------|
| Basic Apartment | Low | Near parks ↑ | Starting building |
| Penthouse | High | Corporate ↑, Parks ↑ | Hard to maximize |
| Housing Complex | Medium | Quantity bonus | Scales with neighbors |

### Commercial
| Building | Base Value | Synergies | Notes |
|----------|------------|-----------|-------|
| Shop | Low | Residential ↑ | Basic commercial |
| Corporate HQ | High | Other corporate ↑ | Chain bonus |
| Mall | Medium | Shops nearby ↑ | Area effect |

### Industrial
| Building | Base Value | Synergies | Notes |
|----------|------------|-----------|-------|
| Factory | Medium | Other factories ↑ | Classic chain |
| Power Plant | High | Powers area | Grid effect |
| Warehouse | Low | Industry ↑ | Support building |

### Government/Public
| Building | Base Value | Synergies | Notes |
|----------|------------|-----------|-------|
| Park | Special | Residential ↑ | Key synergy enabler |
| Plaza | Special | Area bonus | Hard achievement |
| Government Building | Medium | Stability bonus | Late game |

### Illegal
| Building | Base Value | Synergies | Notes |
|----------|------------|-----------|-------|
| TBD | High risk/reward | Negative synergies? | Research needed |

---

## Perk System

Perks are unlocked as you progress through runs and provide persistent bonuses:

### Categories
1. **Income Multipliers** - Flat % increase to certain building types
2. **Synergy Enhancers** - Boost adjacency bonuses
3. **Utility Perks** - Extra rerolls, guaranteed offers, etc.
4. **Special Mechanics** - Unlock unique interactions

### Meta-Progression
- Perks unlock through achievements and milestones
- Choose 4 perks at run start (after unlocking)
- Perk combos create distinct "builds"

---

## Strategic Analysis

### Winning Strategies

#### 1. **Industrial Chains**
Focus on placing factories adjacent to each other for multiplicative bonuses.
- Pros: Consistent, predictable growth
- Cons: Needs good early offerings

#### 2. **Park-Residential Clusters**
Maximize parks surrounded by residential for rent bonuses.
- Pros: High value per tile
- Cons: Parks have no base value

#### 3. **Corporate Towers**
Stack corporate buildings vertically (multi-level).
- Pros: Very high late-game scores
- Cons: Slow start, needs specific perks

#### 4. **Balanced Grid**
Spread building types evenly for consistent income.
- Pros: Flexible, adapts to offerings
- Cons: Lower ceiling than focused builds

### Difficulty Progression

| Days | Phase | Focus |
|------|-------|-------|
| 1-10 | Early | Establish income base |
| 11-25 | Mid | Build synergy clusters |
| 26-40 | Late | Maximize multipliers |
| 41-65+ | Endgame | Push for achievements |

---

## Randomness Analysis

### RNG Elements
1. **Building offerings** - 3 options each turn
2. **Reroll results** - New 3 options
3. **Perk availability** - Varies per run

### Mitigation Strategies
- Save rerolls for critical turns
- Build flexible foundations early
- Prioritize utility perks for consistency

### Community Frustration Points
- "Penthouse achievement needs very lucky draws"
- "Plaza achievement requires specific perk + offering combo"
- "Randomness can make some runs unwinnable"

---

## UI/UX Analysis

### Current Strengths
- Clean, readable building info
- Clear synergy previews
- Smooth camera controls (mouse)

### Current Pain Points
- **Zoom range too limited** - Can't see entire board on wide monitors
- **Controller support incomplete** - Steam Input required, not native
- **Keyboard pan missing** - Only right-click to pan
- **No replay system** - Can't review past runs

### Community Suggestions
1. Extended zoom out option
2. Native controller support
3. WASD pan controls
4. Run history/statistics

---

## Modding Opportunities

### High-Impact, Lower Effort
1. **Balance tweaks** - Adjust building values via data files
2. **New perks** - Data-driven perk additions
3. **Achievement fixes** - Adjust thresholds for frustrating achievements

### Medium Impact, Medium Effort
1. **New building types** - Requires model + data + synergy logic
2. **Larger grid sizes** - Code modification needed
3. **Focus modes** - Weighting system for offerings

### High Impact, High Effort
1. **Endless mode** - Requires progression system overhaul
2. **Multiplayer** - Would need networking layer
3. **Custom campaigns** - Story/scripting system

---

## Comparisons to Similar Games

### vs ISLANDERS
| Aspect | Neongarten | ISLANDERS |
|--------|------------|-----------|
| Grid Type | Hex/vertical | Free placement |
| Progression | Roguelite | Score-based |
| Aesthetic | Cyberpunk | Natural/pastoral |
| Session Length | 10-15 min | 15-30 min |

### vs Luck Be a Landlord
| Aspect | Neongarten | Luck Be a Landlord |
|--------|------------|-------------------|
| Core Mechanic | Spatial placement | Slot machine |
| Synergies | Adjacency | Symbol matching |
| Pacing | Turn-based | Round-based |
| Complexity | Lower | Higher |

---

## Research Tasks

- [ ] Determine exact synergy formulas
- [ ] Map all building types and values
- [ ] Document all perks and effects
- [ ] Identify game engine definitively
- [ ] Find data file formats
- [ ] Test mod injection approaches

---

*Last Updated: January 2026*

