# Neongarten Linux Port Analysis

## Executive Summary

**Verdict: HIGHLY FEASIBLE**

Neongarten is built on Godot 4.3.0, which has excellent native Linux support.
The main barrier is obtaining the original project files or achieving
complete decompilation.

---

## Current State

### Windows Version (Proton)

| Aspect | Status | Notes |
|--------|--------|-------|
| Runs | ✅ Works | Via Proton/Wine |
| Performance | ⚠️ Suboptimal | High CPU/thread overhead |
| Resource Usage | ⚠️ High | Wine translation layer |
| Compatibility | ✅ Good | Most features work |

### Why Native Would Be Better

1. **No Wine/Proton overhead** - Direct syscalls
2. **Better threading** - Native pthreads vs emulated
3. **Lower latency** - No translation layer
4. **Reduced memory** - No Wine state
5. **NixOS integration** - Could package declaratively

---

## Technical Analysis

### What We Have

| Component | Status | Location |
|-----------|--------|----------|
| Game executables | ❌ Windows-only | `.exe` files |
| PCK archives | ✅ Extracted | `recovered/` |
| GDScript source | ✅ Decompiled | 51 scripts, 0 failures |
| Resources | ✅ Converted | 1469 .tres files |
| Scenes | ✅ Exported | 322 .tscn files |
| Shaders | ✅ Readable | .gdshader files |
| Models | ✅ GLB format | Blender-compatible |
| Textures | ✅ PNG format | Standard |
| Translations | ⚠️ 67 keys missing | Minor gaps |

### Missing for Full Rebuild

1. **project.godot** - ✅ Recovered
2. **Import settings** - ✅ Recovered
3. **Editor configuration** - ❌ Not needed for export
4. **Export presets** - ❌ Must recreate

---

## Port Options

### Option 1: Full Project Re-Export (RECOMMENDED)

**Effort: Medium | Success: High**

Steps:
1. ✅ Extract/decompile PCK (DONE)
2. Open recovered project in Godot 4.3.0
3. Fix any decompilation artifacts
4. Create Linux export preset
5. Export as Linux executable

**Challenges:**
- May need to fix minor decompilation issues
- Must match exact Godot 4.3.0 version
- GodotSteam integration needs Linux version

### Option 2: Steam Linux Request

**Effort: Low | Success: Unknown**

Steps:
1. Contact developer (Josh Galecki / Moonroof Studios)
2. Request native Linux build
3. Offer testing assistance

**Rationale:**
- Developer's first Godot game
- Linux export is trivial in Godot
- Growing Linux gaming market

### Option 3: Proton Optimization

**Effort: Low | Success: Medium**

Steps:
1. Profile Proton performance issues
2. Apply custom DXVK/VKD3D settings
3. Use gamescope or MangoHud
4. Optimize Wine prefix

**Doesn't solve:**
- Fundamental translation overhead
- Threading inefficiencies

---

## Godot Linux Export Requirements

### Dependencies

```nix
# NixOS packages needed for Godot 4 Linux games
{
  buildInputs = [
    # Graphics
    vulkan-loader
    vulkan-validation-layers
    libGL
    
    # Audio
    alsa-lib
    pulseaudio
    
    # Input
    libxkbcommon
    
    # Windowing
    wayland
    libX11
    libXcursor
    libXinerama
    libXrandr
    libXi
    
    # Networking (if needed)
    openssl
  ];
}
```

### Export Template

```bash
# Download Godot 4.3.0 export templates
godot_4 --headless --export-release "Linux/X11" neongarten.x86_64

# Or for specific architectures
godot_4 --headless --export-release "Linux/X11 64-bit" neongarten.x86_64
```

---

## GodotSteam Considerations

The game uses GodotSteam for:
- Achievements
- Cloud saves (if any)
- Steam overlay integration

### Linux GodotSteam

From `player/godot_steam.gd`:
```gdscript
extends Node
# Autoloaded as "GodotSteam"
```

**Solution:**
1. Use GodotSteam Linux build
2. Or create stub for non-Steam version
3. Achievements still work through Steam API

---

## Performance Expectations

### Windows (Proton)

Based on user reports and typical Proton overhead:

| Metric | Estimate |
|--------|----------|
| CPU overhead | +15-30% |
| Memory overhead | +200-500MB |
| Thread efficiency | 60-80% native |
| Frame latency | +1-3ms |

### Native Linux (Expected)

| Metric | Estimate |
|--------|----------|
| CPU overhead | 0% (native) |
| Memory overhead | 0% (native) |
| Thread efficiency | 100% |
| Frame latency | Optimal |

---

## Implementation Plan

### Phase 1: Validation (1-2 hours)

1. Install Godot 4.3.0 editor on NixOS
2. Open recovered project
3. Assess errors/warnings
4. Document required fixes

### Phase 2: Fixes (2-4 hours)

1. Fix any decompilation artifacts
2. Replace Windows-specific code paths
3. Test GodotSteam Linux compatibility
4. Verify all resources load

### Phase 3: Export (1 hour)

1. Create Linux export preset
2. Export with debug symbols
3. Test on NixOS
4. Profile performance

### Phase 4: Packaging (2-4 hours)

1. Create NixOS derivation
2. Handle Steam runtime
3. Desktop entry and icons
4. Documentation

---

## NixOS Packaging Sketch

```nix
{ stdenv, fetchurl, godot_4, steam-run }:

stdenv.mkDerivation rec {
  pname = "neongarten-linux";
  version = "1.0-mod";

  # Built from recovered project
  src = ./neongarten.x86_64;

  nativeBuildInputs = [ ];
  buildInputs = [ godot_4 ];

  installPhase = ''
    mkdir -p $out/bin $out/share/neongarten
    cp -r * $out/share/neongarten/
    
    # Wrapper script
    cat > $out/bin/neongarten << EOF
    #!/bin/sh
    exec $out/share/neongarten/neongarten.x86_64 "\$@"
    EOF
    chmod +x $out/bin/neongarten
  '';

  meta = {
    description = "Neongarten - Native Linux build";
    platforms = [ "x86_64-linux" ];
    license = "proprietary"; # Still needs original purchase
  };
}
```

---

## Legal Considerations

### What's Allowed

- **Personal use**: Port for yourself ✅
- **Modding**: Modify your purchased copy ✅
- **Tooling**: Create mod tools ✅

### What's NOT Allowed

- **Distribution**: Share ported executable ❌
- **Bypass DRM**: If Steam DRM present (unlikely for Godot) ❌
- **Commercial use**: Sell modifications ❌

### Best Path Forward

1. Build port tools, not ports
2. Share instructions, not binaries
3. Engage with developer positively
4. Offer to help with official port

---

## Developer Contact Strategy

### Message Template

```
Subject: Linux Port Assistance for Neongarten

Hi Josh,

I'm a big fan of Neongarten! I noticed it's built with Godot 4.3,
which has excellent native Linux support.

I'm running NixOS and would love to play without Proton overhead.
Would you consider an official Linux build? Godot makes this nearly
trivial - just an export preset change.

I'd be happy to help test if you'd like to explore this!

Best,
[Name]
```

### Contact Points

- **Discord**: discord.gg/HvtvGbSwax (official server)
- **Steam**: Community discussions
- **Publisher**: Goblinz Publishing

---

## Next Steps

1. **Immediate**: Test opening recovered project in Godot editor
2. **Short-term**: Document any fixes needed
3. **Medium-term**: Create working Linux export
4. **Long-term**: Engage with developer for official support

---

*Analysis based on decompiled Neongarten v1.0 (Godot 4.3.0)*

