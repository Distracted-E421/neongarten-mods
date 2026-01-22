# Wayland Input Workarounds - Research & Implementation

## The Problem

Wayland's security model prevents:
- Sending input to windows without focus
- Applications reading/writing to other windows
- Global hotkey registration without compositor support

This is intentional security, but breaks legitimate automation use cases.

## Available Solutions (NixOS Packages)

### Tier 1: Works Today

#### 1. `ydotool` - Virtual Input Device

```bash
# Install
nix-shell -p ydotool

# Requires ydotoold daemon running as root
sudo ydotoold &

# Then send input (goes to FOCUSED window)
ydotool type "Hello World"
ydotool click 0x40  # left click
ydotool mousemove 100 200
```

**Limitation**: Input goes to currently focused window only.

#### 2. `dotool` - uinput-based Input Simulation

```bash
# Install
nix-shell -p dotool

# Requires uinput access (add user to input group or run as root)
echo "type hello" | dotool
echo "click left" | dotool
```

**Limitation**: Same as ydotool - focused window only.

#### 3. `kdotool` - KDE-Specific xdotool Clone

```bash
# Install (KDE Plasma only)
nix-shell -p kdotool

# Can interact with KDE D-Bus for some operations
kdotool search --name "Godot"  # Find window
kdotool windowactivate <window_id>  # Focus window
```

**Advantage**: Can programmatically focus windows before sending input.
**Limitation**: Still requires focus for actual input.

#### 4. `wtype` - Wayland Type Tool

```bash
# Install
nix-shell -p wtype

# Type text (requires focus)
wtype "Hello"
wtype -k Return  # Press enter
```

**Limitation**: Focused window only.

### Tier 2: Nested Compositor Approach ⭐ RECOMMENDED

The only way to send input to an unfocused application is to run it in its own compositor where you control focus.

#### Option A: `cage` - Single-App Wayland Kiosk

```bash
# Run Godot in its own isolated Wayland session
cage -- godot --editor ~/neongarten-mods/recovered/ &

# Now you can:
# 1. Screenshot this compositor (separate from main desktop)
# 2. Send input via wayvnc
# 3. The app always has "focus" within its compositor
```

**Setup**:
```bash
# Create a script to launch Godot in cage
#!/usr/bin/env bash
export WLR_NO_HARDWARE_CURSORS=1  # If needed
cage -s -- godot --editor "$1"
```

#### Option B: `gamescope` - Gaming-Oriented Compositor

Valve's SteamOS compositor, designed for running games in isolation.

```bash
# Run Godot in gamescope
gamescope -W 1920 -H 1080 -- godot --editor ~/neongarten-mods/recovered/ &

# gamescope provides:
# - Isolated compositor
# - Scaling/filtering
# - Screen capture integration
```

**Advantages**:
- Specifically designed for this use case (Steam Deck)
- Good performance
- Can embed in parent compositor

#### Option C: `wayvnc` - VNC into Nested Compositor

```bash
# Start cage with wayvnc
cage -- godot --editor ~/neongarten-mods/recovered/ &
wayvnc 0.0.0.0 5900  # Expose VNC server

# Now connect with any VNC client and send input remotely
# This gives FULL input control without focus issues
```

### Tier 3: D-Bus/Portal APIs

Modern Wayland has portal APIs for screen sharing and remote input, but support varies.

#### `xdg-desktop-portal` Remote Desktop

```bash
# Check if available
dbus-send --session --print-reply \
  --dest=org.freedesktop.portal.Desktop \
  /org/freedesktop/portal/desktop \
  org.freedesktop.DBus.Introspectable.Introspect
```

KDE Plasma has `org.kde.KWin` D-Bus interface but input control is limited.

## Recommended Architecture for Godot AI Harness

### Phase 1: Nested Compositor Setup

```
┌─────────────────────────────────────────────────────┐
│ Main KDE Session (Obsidian Desktop)                 │
│                                                     │
│  ┌──────────────────────┐  ┌─────────────────────┐  │
│  │ Cursor IDE           │  │ cage/gamescope      │  │
│  │ (AI Agent here)      │  │ ┌─────────────────┐ │  │
│  │                      │  │ │ Godot Editor    │ │  │
│  │                      │  │ │ (isolated)      │ │  │
│  │ AI → Commands ─────────→ │                 │ │  │
│  │                      │  │ └─────────────────┘ │  │
│  │ Screenshot ←──────────── [capture]           │  │
│  └──────────────────────┘  └─────────────────────┘  │
│                                                     │
│  Dell Monitor            AI Monitor (dedicated)     │
└─────────────────────────────────────────────────────┘
```

### Phase 2: Input Bridge

```bash
# Create input bridge script
#!/usr/bin/env bash
# ai-godot-input - Send input to nested Godot

GODOT_SOCKET=/tmp/godot-input.sock

case "$1" in
  click)
    # Focus the cage window, send click, return focus
    kdotool windowactivate $(kdotool search --name "cage") 
    ydotool click 0x40
    kdotool windowactivate $(kdotool search --name "Cursor")
    ;;
  type)
    kdotool windowactivate $(kdotool search --name "cage")
    ydotool type "$2"
    kdotool windowactivate $(kdotool search --name "Cursor")
    ;;
  navigate)
    # Custom Godot-specific commands via editor plugin
    ;;
esac
```

### Phase 3: Godot Editor Plugin

For the smoothest experience, build a Godot editor plugin that:

1. Listens on a TCP/Unix socket
2. Accepts JSON commands
3. Executes editor operations programmatically
4. Returns screenshots/state

This bypasses all Wayland restrictions because Godot does the work internally.

```gdscript
# addons/ai_bridge/ai_bridge.gd
@tool
extends EditorPlugin

var server: TCPServer
var port: int = 9876

func _enter_tree():
    server = TCPServer.new()
    server.listen(port)
    print("[AI Bridge] Listening on port %d" % port)

func _process(_delta):
    if server.is_connection_available():
        var client = server.take_connection()
        handle_client(client)

func handle_client(client: StreamPeerTCP):
    var json = client.get_string()
    var cmd = JSON.parse_string(json)
    
    var result = {}
    match cmd.action:
        "screenshot":
            # Capture viewport and save
            var img = get_editor_interface().get_edited_scene_root().get_viewport().get_texture().get_image()
            img.save_png("/tmp/godot_screenshot.png")
            result = {"path": "/tmp/godot_screenshot.png"}
        "open_scene":
            get_editor_interface().open_scene_from_path(cmd.path)
            result = {"success": true}
        "select_node":
            var node = get_editor_interface().get_edited_scene_root().get_node(cmd.path)
            get_editor_interface().edit_node(node)
            result = {"success": true}
        "get_selected":
            var selected = get_editor_interface().get_selection().get_selected_nodes()
            result = {"nodes": selected.map(func(n): return n.name)}
        "navigate_filesystem":
            get_editor_interface().get_file_system_dock().navigate_to_path(cmd.path)
            result = {"success": true}
    
    client.put_string(JSON.stringify(result))
```

## NixOS Configuration

Add to your system/home configuration:

```nix
# For nested compositor approach
environment.systemPackages = with pkgs; [
  cage        # Single-app compositor
  gamescope   # Gaming compositor
  wayvnc      # VNC server
  ydotool     # Input simulation
  kdotool     # KDE-specific automation
];

# Enable ydotool service
services.ydotool.enable = true;

# Or with Home Manager
programs.ydotool = {
  enable = true;
};
```

## Quick Start Commands

### Option 1: Gamescope (Recommended for Performance)

```bash
# Start Godot in gamescope
gamescope -W 1920 -H 1080 -o 15 -- godot --editor ~/neongarten-mods/recovered/

# -W/-H: resolution
# -o: FPS limit (reduce overhead)
```

### Option 2: Cage + VNC (Full Remote Control)

```bash
# Terminal 1: Start cage with Godot
cage -- godot --editor ~/neongarten-mods/recovered/

# Terminal 2: Start VNC server
wayvnc 127.0.0.1 5900

# Now use any VNC client to interact
# Or use libvncserver bindings for programmatic control
```

### Option 3: Focus-Swap Method (Simple but Disruptive)

```bash
# ai-click.sh - Click at coordinates, return focus
#!/usr/bin/env bash
GODOT_WIN=$(kdotool search --name "Godot Engine")
CURSOR_WIN=$(kdotool search --name "Cursor")

kdotool windowactivate $GODOT_WIN
sleep 0.1
ydotool mousemove --absolute $1 $2
ydotool click 0x40
sleep 0.1
kdotool windowactivate $CURSOR_WIN
```

## Summary

| Approach | Focus Required | Full Control | Performance | Complexity |
|----------|---------------|--------------|-------------|------------|
| ydotool/dotool | Yes | No | Best | Low |
| kdotool + focus swap | Brief | Yes | Good | Medium |
| gamescope | No | Yes | Good | Medium |
| cage + wayvnc | No | Yes | OK | Medium |
| Editor plugin | No | Full | Best | High |

**Recommendation**: Start with **gamescope** for isolated Godot + **kdotool** for focus management. Add **editor plugin** later for seamless integration.

## Next Steps

1. Test gamescope with Godot on dedicated monitor
2. Build focus-swap helper script
3. Design editor plugin API
4. Integrate with ai-monitor-capture tool

