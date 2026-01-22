# AI Interaction Strategies for Godot

## The Core Challenge

**Wayland security model** prevents applications from:
- Sending input to windows they don't own
- Grabbing keyboard/mouse without user consent
- Interacting with windows without focus

This is by design - prevents keyloggers and click-jacking. But it makes AI-driven GUI automation hard.

## Available Approaches

### 1. File-Based Interaction (Best for Modding) ✅

**How it works**: Modify Godot project files directly; Godot auto-reloads.

**Pros**:
- No focus needed
- Works on any Wayland/X11/WM
- Fast and reliable
- Perfect for modding workflow

**What we can do**:
- Modify `.tres` resource files (building stats, perks)
- Edit `.gd` scripts
- Change `.tscn` scene files
- Swap asset files

**Example**:
```bash
# Change a building's income
sed -i 's/income = 1/income = 5/' recovered/structures/bar.tres
# Godot will auto-reload if watching files
```

### 2. Godot CLI/Headless Mode ✅

**How it works**: Run Godot commands without GUI.

**Pros**:
- No focus needed
- Can run scripts, export, validate
- Good for batch operations

**Commands**:
```bash
# Validate project
godot --headless --check-only --path recovered/

# Run a custom script
godot --headless --path recovered/ --script scripts/export_data.gd

# Export project
godot --headless --path recovered/ --export-release "Linux" output/game
```

### 3. D-Bus/KWin Scripting (KDE-Specific)

**How it works**: KDE exposes some window management via D-Bus.

**Pros**:
- Can resize, move, minimize windows
- Query window properties

**Limitations**:
- Cannot send keystrokes/clicks to specific windows
- KDE-only

**Example**:
```bash
# List windows
qdbus org.kde.KWin /KWin org.kde.KWin.queryWindowInfo

# Move window to specific desktop
qdbus org.kde.KWin /KWin org.kde.KWin.sendToDesktop <window_id> 2
```

### 4. ydotool (Limited)

**How it works**: Virtual input device that sends events to focused window.

**Limitations**:
- Sends input to **currently focused** window only
- Must steal focus, defeating the purpose

### 5. Nested Compositor/VNC (Complex)

**How it works**: Run Godot inside a nested Wayland/X11 session, interact via VNC.

**Pros**:
- Full interaction capability
- Isolated from main session

**Cons**:
- Complex setup
- Performance overhead
- Needs dedicated resources

**Setup**:
```bash
# Start nested Wayland with Godot
cage godot --editor recovered/ &

# Connect via VNC or wayvnc
wayvnc 0.0.0.0 5900
```

### 6. Godot Editor Plugin (Future Possibility)

**How it works**: Create an editor plugin that exposes a socket/HTTP API.

**Pros**:
- Direct editor control
- Can do anything the editor can
- Works on any platform

**Cons**:
- Requires development
- Must maintain compatibility with Godot versions

**Concept**:
```gdscript
# addons/ai_bridge/ai_bridge.gd
extends EditorPlugin

var server := TCPServer.new()

func _enter_tree():
    server.listen(9999)

func _process(_delta):
    if server.is_connection_available():
        var client = server.take_connection()
        var command = client.get_string()
        execute_command(command)
        client.put_string("OK")

func execute_command(cmd: String):
    match cmd.split(" ")[0]:
        "open_scene": EditorInterface.open_scene_from_path(cmd.split(" ")[1])
        "select_node": # etc
```

## Recommended Strategy for Neongarten Modding

### Immediate (No Focus Needed)

1. **Screenshot** → `ai-monitor-capture` (working ✅)
2. **Read project data** → `gdharness list-structures/list-scenes`
3. **Modify resources** → Direct file editing (`.tres`, `.gd`, `.tscn`)
4. **Batch operations** → Godot `--headless` mode

### For Visual Asset Inspection

1. Take screenshot with `ai-monitor-capture`
2. Analyze what's visible
3. **Ask user to navigate** via dialog: "Please click on sprites folder"
4. Screenshot again

### Future Enhancement

Build a **Godot Editor Plugin** that:
- Listens on a local port
- Accepts JSON commands
- Returns screenshots/data
- Can navigate FileSystem, select nodes, etc.

## WM-Independent Solution

The **file-based approach** works everywhere:

| WM | Screenshot | File Edit | Godot CLI |
|----|-----------|-----------|-----------|
| KDE Plasma | spectacle -b | ✅ | ✅ |
| Hyprland | grim | ✅ | ✅ |
| Sway | grim | ✅ | ✅ |
| GNOME | gnome-screenshot | ✅ | ✅ |
| X11 (any) | import/scrot | ✅ | ✅ |

### Making Screenshot WM-Independent

```bash
#!/usr/bin/env bash
# Universal screenshot tool

if command -v spectacle &>/dev/null; then
    spectacle -b -f -o "$1"  # KDE
elif command -v grim &>/dev/null; then
    grim "$1"  # wlroots (Hyprland, Sway)
elif command -v gnome-screenshot &>/dev/null; then
    gnome-screenshot -f "$1"  # GNOME
elif command -v import &>/dev/null; then
    import -window root "$1"  # X11 (ImageMagick)
elif command -v scrot &>/dev/null; then
    scrot "$1"  # X11 fallback
else
    echo "No screenshot tool found"
    exit 1
fi
```

## Summary

| Need | Solution | Focus Required |
|------|----------|----------------|
| See Godot state | Screenshot | ❌ No |
| Modify game data | Edit .tres files | ❌ No |
| Run scripts | Godot --headless | ❌ No |
| Export game | Godot --export | ❌ No |
| Click UI buttons | User action via dialog | ✅ Yes |
| Navigate FileSystem | User action OR future plugin | ✅ Yes |

**Bottom line**: For modding, we can do 90% of work without focus. For navigation, we ask the user via dialog when needed.

