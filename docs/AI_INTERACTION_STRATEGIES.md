# AI Interaction Strategies for Godot Editor

This document outlines the current capabilities and limitations for AI interaction with the Godot editor, particularly focusing on operating within a Wayland environment where direct input to unfocused windows is restricted.

## ✅ WORKING: EIS (Emulated Input System) via Portals

**Status: FULLY FUNCTIONAL as of January 2026**

We have successfully implemented unfocused input injection using the XDG Desktop Portal's RemoteDesktop interface with EIS (Emulated Input System).

### How It Works

1. **Portal Request**: The AI requests RemoteDesktop access via D-Bus portal
2. **User Consent**: User approves the one-time consent dialog (per session)
3. **EIS Connection**: Portal provides an EIS socket for input injection
4. **Direct Input**: AI can send absolute pointer motion, clicks, and keyboard input

### Working Commands

```bash
# Check portal status
./tools/portal-input/target/release/portal-input status

# View EIS regions and coordinate mapping
./tools/portal-input/target/release/portal-input eis

# Move cursor to absolute position
./tools/portal-input/target/release/portal-input eis-send -x 768 -y 1200

# Move and click
./tools/portal-input/target/release/portal-input eis-send -x 768 -y 1200 --click

# Move with visual shake (for debugging)
./tools/portal-input/target/release/portal-input eis-send -x 768 -y 1200 --shake
```

### Monitor Region Mapping (Current System)

From EIS device regions:

| Region | X | Y | Width | Height | Scale | Description |
|----|----|----|----|----|----|-----|
| [0] | 1536 | 700 | 1707 | 960 | 1.5 | Main monitor (center) |
| [1] | 0 | 796 | 1536 | 864 | 1.25 | Dell E2420H (top-left, AI monitor) |
| [2] | 4323 | 796 | 1080 | 1920 | 1.0 | Right portrait monitor |
| [3] | 0 | 1660 | 1536 | 864 | 1.25 | Samsung TV (bottom-left) |
| [4] | 1536 | 1660 | 1536 | 864 | 1.25 | Bottom-center |
| [5] | 3243 | 0 | 1080 | 1920 | 1.0 | Top-right portrait |

### Dell Monitor (AI Monitor) - Region [1]

- **EIS Coordinates**: x: 0-1536, y: 796-1660
- **Physical Resolution**: 1920x1080 (at 1.25 scale)
- **Center point**: (768, 1228)
- **Top area** (title bars): y ~800-850
- **Content area**: y ~850-1600

## Current Capabilities

### 1. Visual Observation (Screenshots)
- **Tool**: `./tools/godot-harness/ai-monitor-capture capture`
- **Method**: `grim` (Wayland native), region-cropped
- **Coordinates**: Dell monitor at (0, 1570) for 3070x1750 region
- **Use**: See the current state of Godot editor

### 2. Absolute Pointer Motion (EIS)
- **Tool**: `portal-input eis-send -x X -y Y`
- **Coordinate System**: EIS region coordinates (see table above)
- **Use**: Move cursor to specific UI elements

### 3. Mouse Clicks (EIS)
- **Tool**: `portal-input eis-send -x X -y Y --click`
- **Use**: Click buttons, select items, interact with UI

### 4. Keyboard Input (EIS)
- **Status**: Available via EIS keyboard device
- **Not yet implemented in CLI** - requires adding key subcommand

### 5. Direct File Manipulation
- **Tool**: Standard CLI tools (cat, sed, grep, etc.)
- **Use**: Edit GDScript, .tres resources, .tscn scenes
- **Benefit**: Godot auto-reloads on file changes

## Workflow for AI-Assisted Modding

1. **Take Screenshot**: Capture Dell monitor to see Godot state
2. **Analyze UI**: Identify coordinates of target elements
3. **Send Input**: Use EIS to click/interact with identified elements
4. **Verify**: Take another screenshot to confirm action

### Example: Click a Button

```bash
# 1. Capture current state
./tools/godot-harness/ai-monitor-capture capture

# 2. Analyze screenshot to find button coordinates (in EIS region space)
# Dell monitor is region [1], so coords are relative to (0, 796) + scaled

# 3. Click at the identified position
./tools/portal-input/target/release/portal-input eis-send -x 400 -y 1000 --click

# 4. Verify
./tools/godot-harness/ai-monitor-capture capture
```

## Limitations

### Consent Dialog
- **Issue**: KDE doesn't support persistent RemoteDesktop sessions
- **Impact**: Each new portal-input invocation requires user consent
- **Workaround**: Future daemon mode to keep session alive

### Coordinate Translation
- EIS coordinates use a scaled coordinate system
- Must account for monitor scale factor (1.25 for Dell)
- Regions have offset positions that must be added

### Response Time
- Portal setup takes ~1-2 seconds per session
- EIS handshake adds ~0.5 seconds
- Not suitable for rapid-fire interactions

## Architecture

```
┌─────────────────────────────────────────────────┐
│ KDE Plasma / Wayland                            │
│                                                 │
│  ┌─────────────┐    ┌────────────────────────┐  │
│  │ Cursor IDE  │    │ XDG Desktop Portal     │  │
│  │ (AI Agent)  │    │                        │  │
│  │             │    │  ┌──────────────────┐  │  │
│  │ portal-input├────┼──│ RemoteDesktop    │  │  │
│  │             │    │  │  ├─ EIS Socket   │  │  │
│  │             │    │  │  └─ Screencast   │  │  │
│  └─────────────┘    │  └──────────────────┘  │  │
│                     └────────────────────────┘  │
│                                                 │
│  ┌─────────────────┐                            │
│  │ Godot Editor    │  ← Receives EIS input      │
│  │ (Dell Monitor)  │    without needing focus   │
│  └─────────────────┘                            │
└─────────────────────────────────────────────────┘
```

## Technical Implementation

### Key Libraries
- **ashpd**: Rust async XDG portal client
- **reis**: Rust EIS (Emulated Input System) protocol implementation
- **grim**: Wayland screenshot tool

### EIS Protocol Flow
1. Connect to portal RemoteDesktop
2. Request device selection (keyboard + pointer)
3. Request screencast (for coordinate info)
4. Get EIS socket via `connect_to_eis()`
5. Perform EIS handshake (negotiate interfaces)
6. Bind seat capabilities (pointer_absolute, button, etc.)
7. Wait for device events
8. Start emulating → send input → frame → stop emulating

### Button Codes (Linux input-event-codes.h)
- **BTN_LEFT**: 272 (0x110)
- **BTN_RIGHT**: 273 (0x111)
- **BTN_MIDDLE**: 274 (0x112)

## Future Enhancements

### 1. Daemon Mode
Keep portal session alive for multiple operations:
- Start daemon on first call
- Subsequent calls communicate via socket/pipe
- Eliminates consent dialog for each interaction

### 2. Keyboard Input CLI
Add keyboard subcommand:
```bash
portal-input eis-key --text "Hello"
portal-input eis-key --keycode 28  # Enter
```

### 3. Godot Editor Plugin
Direct control without EIS:
- Plugin exposes HTTP/WebSocket API
- AI sends commands like `{"action": "open_scene", "path": "res://..."}`
- Plugin executes internally

### 4. Region Auto-Detection
Detect which EIS region corresponds to which physical monitor:
- Match region dimensions to display outputs
- Auto-calculate EIS coordinates from physical coords

## References

- [XDG Desktop Portal Spec](https://flatpak.github.io/xdg-desktop-portal/)
- [libei/libeis](https://gitlab.freedesktop.org/libinput/libei)
- [reis crate](https://crates.io/crates/reis)
- [ashpd crate](https://crates.io/crates/ashpd)
