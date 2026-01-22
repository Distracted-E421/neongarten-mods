# stl-next Godot Integration Design

## Overview

This document outlines the integration of Godot PCK mod management into stl-next,
enabling modding support for Neongarten and other Godot games.

---

## stl-next Architecture Summary

stl-next is written in Zig with a modular architecture:

```
src/
├── modding/          # Mod manager integration (target for Godot)
│   ├── mod.zig       # Module exports
│   ├── manager.zig   # MO2/Vortex detection, NXM handling
│   ├── stardrop.zig  # Stardew Valley specific
│   └── vortex.zig    # Vortex integration
├── tinkers/          # Game enhancement modules
├── engine/           # Steam integration
└── core/             # Config, launcher
```

---

## Proposed Changes

### New Module: `src/modding/godot.zig`

```zig
//! Godot PCK Mod Manager
//!
//! Support for:
//! - PCK file inspection/extraction
//! - Mod PCK overlay (load order)
//! - RNG profile injection
//! - Script patching

pub const GodotModManager = struct {
    allocator: std.mem.Allocator,
    game_path: []const u8,
    mods_path: []const u8,
    
    pub fn init(allocator: std.mem.Allocator, game_path: []const u8) !GodotModManager {
        // ...
    }
    
    /// List contents of a PCK file
    pub fn listPck(self: *GodotModManager, pck_path: []const u8) ![]PckEntry {
        // ...
    }
    
    /// Extract PCK to directory
    pub fn extractPck(self: *GodotModManager, pck_path: []const u8, output: []const u8) !void {
        // ...
    }
    
    /// Pack directory to PCK
    pub fn createPck(self: *GodotModManager, input_dir: []const u8, output: []const u8) !void {
        // ...
    }
    
    /// Generate launch args for PCK mod loading
    pub fn getModLaunchArgs(self: *GodotModManager) ![]const u8 {
        // Returns: --main-pack <mod.pck> or similar
    }
};

pub const PckEntry = struct {
    path: []const u8,
    offset: u64,
    size: u64,
    compressed_size: u64,
    md5: [16]u8,
    flags: u32,
};

pub const RngProfile = struct {
    name: []const u8,
    building_weights: struct {
        common: u8,
        uncommon: u8,
        rare: u8,
    },
    perk_weights: struct {
        common: u8,
        uncommon: u8,
    },
    difficulty_modifiers: struct {
        shanty_count: u8,
        starting_rerolls: u8,
        starting_hacks: u8,
    },
};
```

---

## PCK Format Implementation

### Header Structure (Godot 4.x)

```zig
const PckHeader = packed struct {
    magic: [4]u8,           // "GDPC"
    version: u32,           // Pack format version (2 for Godot 4.x)
    godot_major: u32,       // Godot major version
    godot_minor: u32,       // Godot minor version
    godot_patch: u32,       // Godot patch version
    flags: u32,             // Encryption/compression flags
    file_base_offset: u64,  // Offset where files start
    reserved: u64,          // Reserved (0)
    file_count: u32,        // Number of files
};

const PckFileEntry = packed struct {
    path_length: u32,       // Length of path string
    // path: [path_length]u8, // UTF-8 path
    offset: u64,            // Offset in pack
    size: u64,              // Uncompressed size
    md5: [16]u8,            // MD5 checksum
    flags: u32,             // File flags
};
```

### Implementation Strategy

1. **Parse existing godotpcktool behavior** (Nix package available)
2. **Implement native Zig reader** for speed
3. **Support both read and write** operations
4. **Handle Godot 4.x format** (version 2 pack)

---

## Mod Loading Approaches

### Option 1: PCK Override (Recommended)

Godot supports loading override PCKs via `--main-pack`:

```bash
# Original launch
./Neongarten.exe

# With mod pack overlay
./Neongarten.exe --main-pack mods/rng_sliders.pck
```

**stl-next Integration:**

```zig
pub fn getLaunchCommand(self: *GodotModManager, original_cmd: []const u8) ![]const u8 {
    var args = std.ArrayList(u8).init(self.allocator);
    
    try args.appendSlice(original_cmd);
    
    // Add mod PCKs in load order
    for (self.enabled_mods.items) |mod| {
        try args.appendSlice(" --main-pack ");
        try args.appendSlice(mod.pck_path);
    }
    
    return args.toOwnedSlice();
}
```

### Option 2: PCK Patching

Directly modify the game PCK (less safe, but works without command line):

```zig
pub fn patchPck(
    self: *GodotModManager,
    original_pck: []const u8,
    patch_pck: []const u8,
    output_pck: []const u8,
) !void {
    // 1. Read both PCKs
    // 2. Merge file lists (patch overrides original)
    // 3. Write combined PCK
}
```

### Option 3: Resource Injection (Advanced)

For RNG profiles, inject modified .tres resources:

```zig
pub fn injectRngProfile(
    self: *GodotModManager,
    profile: RngProfile,
) !void {
    // 1. Generate modified CityScreen.gd with profile values
    // 2. Compile to GDC (bytecode)
    // 3. Create overlay PCK with just the modified script
}
```

---

## CLI Commands

### Proposed stl-next Commands

```bash
# List PCK contents
stl-next godot-pck list /path/to/game.pck

# Extract PCK
stl-next godot-pck extract /path/to/game.pck ./output/

# Pack directory to PCK
stl-next godot-pck pack ./modded/ ./output/mod.pck

# Validate PCK
stl-next godot-pck validate /path/to/mod.pck

# Apply RNG profile (Neongarten-specific)
stl-next neongarten profile apply "Rare Hunter"

# List available profiles
stl-next neongarten profile list

# Create profile
stl-next neongarten profile create "My Profile" --common 4 --uncommon 6 --rare 5
```

---

## Integration with Existing stl-next

### Tinker Module: `src/tinkers/godot.zig`

```zig
pub const GodotTinker = struct {
    pub const name = "godot";
    pub const description = "Godot game enhancements (PCK mods, RNG profiles)";
    
    config: struct {
        enabled: bool = false,
        mod_packs: []const []const u8 = &.{},
        rng_profile: ?[]const u8 = null,
    },
    
    pub fn apply(self: *GodotTinker, ctx: *TinkerContext) !void {
        if (!self.config.enabled) return;
        
        // Add PCK arguments
        for (self.config.mod_packs) |pck| {
            try ctx.addLaunchArg("--main-pack");
            try ctx.addLaunchArg(pck);
        }
    }
};
```

### Game-Specific Config: Neongarten

```zig
pub const NeongtenConfig = struct {
    // Game identification
    app_id: u32 = 3211750,
    exe_name: []const u8 = "Neongarten.exe",
    
    // Mod paths
    mods_dir: []const u8 = "stl-next/mods/neongarten",
    profiles_dir: []const u8 = "stl-next/profiles/neongarten",
    
    // Default RNG profile
    default_profile: ?[]const u8 = null,
    
    // Mod load order
    load_order: []const []const u8 = &.{},
};
```

---

## User Workflow

### Installing a Mod

```bash
# 1. User downloads mod (e.g., rng_sliders.pck)

# 2. Enable with stl-next
stl-next godot-mod enable neongarten ./downloads/rng_sliders.pck
# → Copies to ~/.local/share/stl-next/mods/neongarten/
# → Updates load order

# 3. Launch game
stl-next run 3211750  # Neongarten
# → Automatically adds --main-pack arguments
```

### Using RNG Profiles

```bash
# 1. Create a profile via TUI or CLI
stl-next neongarten profile create "Easy Mode" \
  --common 4 --uncommon 8 --rare 6 \
  --shanties 0 --rerolls 10

# 2. Set as default
stl-next neongarten profile set "Easy Mode"

# 3. Launch (profile applied automatically)
stl-next run 3211750
```

---

## File Structure

### stl-next Data Directory

```
~/.local/share/stl-next/
├── mods/
│   └── neongarten/
│       ├── rng_sliders.pck
│       └── load_order.json
├── profiles/
│   └── neongarten/
│       ├── Easy Mode.json
│       ├── Rare Hunter.json
│       └── default → Easy Mode.json
└── cache/
    └── pck/
        └── neongarten/
            └── extracted/  # Cached extractions
```

### Profile JSON Format

```json
{
  "name": "Easy Mode",
  "version": "1.0",
  "game": "neongarten",
  "created": "2026-01-22T12:00:00Z",
  
  "building_weights": {
    "common": 4,
    "uncommon": 8,
    "rare": 6
  },
  "perk_weights": {
    "common": 2,
    "uncommon": 4
  },
  "difficulty": {
    "shanty_apartments": 0,
    "starting_rerolls": 10,
    "starting_hacks": 5
  },
  "perk_modifiers": {
    "solar_punk_bonus": 3,
    "i_am_legion_bonus": 6
  }
}
```

---

## Implementation Phases

### Phase 1: PCK Tools (Foundation)

- [ ] Implement PCK header parsing
- [ ] Implement file listing
- [ ] Implement extraction
- [ ] Add CLI commands

### Phase 2: Mod Management

- [ ] Create mod registry
- [ ] Implement load order
- [ ] Add enable/disable commands
- [ ] Launch argument injection

### Phase 3: RNG Profiles (Neongarten-specific)

- [ ] Profile CRUD operations
- [ ] Script patching for profile injection
- [ ] PCK generation from profiles
- [ ] TUI for profile editing

### Phase 4: Polish

- [ ] TUI mod browser
- [ ] Steam Workshop detection (if applicable)
- [ ] Nexus Mods integration for Godot games
- [ ] Backup/restore functionality

---

## Dependencies

### NixOS Packages

```nix
buildInputs = [
  godotpcktool  # Reference implementation
  # OR native Zig implementation
];
```

### External Tools (Optional)

- `gdsdecomp` - For full project recovery
- `gdtoolkit_4` - For GDScript validation

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Game updates break mods | High | Medium | Version pinning, validation |
| PCK format changes | Low | High | Abstract format handling |
| Performance issues | Low | Low | Lazy loading, caching |
| Steam integrity check | Medium | Medium | Don't modify base game |

---

## Success Criteria

1. ✅ Can list/extract/create PCK files
2. ✅ Can manage mod load order
3. ✅ Can create/apply RNG profiles
4. ✅ Launch games with mods via stl-next
5. ✅ Works with Neongarten specifically
6. ✅ Extensible to other Godot games

---

*Design document for stl-next Godot integration - January 2026*

