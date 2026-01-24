# Portal Input - Wayland Unfocused Input via EIS

A tool for injecting mouse and keyboard input on Wayland without requiring window focus, using the XDG Desktop Portal RemoteDesktop interface with EIS (Emulated Input System).

## Building

```bash
cd tools/portal-input
nix-shell -p cargo rustc pkg-config dbus.dev --run "cargo build --release"
```

## Commands

### Check Portal Status
```bash
./target/release/portal-input status
```

### View EIS Regions (One-Shot)
```bash
./target/release/portal-input eis
```
Shows coordinate regions for all monitors. Each invocation requires consent dialog.

### Send Input (One-Shot)
```bash
# Move cursor to absolute position
./target/release/portal-input eis-send -x 768 -y 1200

# Move and click
./target/release/portal-input eis-send -x 768 -y 1200 --click

# Move with visual shake
./target/release/portal-input eis-send -x 768 -y 1200 --shake
```
Each invocation requires consent dialog.

### Daemon Mode (Recommended)
```bash
# Start daemon (one consent dialog)
./target/release/portal-input daemon

# In another terminal, send commands:
echo "move 768 1200" | socat - UNIX-CONNECT:/tmp/portal-input.sock

# Or pipe commands directly:
echo -e "move 768 1200\nclick 500 900\nquit" | ./target/release/portal-input daemon
```

Commands accepted in daemon mode:

**Pointer:**
- `move X Y` - Move cursor to absolute position
- `click X Y` - Move and left-click
- `rclick X Y` - Move and right-click
- `scroll DX DY` - Discrete scroll (wheel clicks, DY positive=down)
- `scrollpx DX DY` - Smooth pixel-precise scroll

**Keyboard:**
- `key KEYCODE` - Press and release a key (Linux input keycode)
- `keydown KEYCODE` - Press key down (hold)
- `keyup KEYCODE` - Release key
- `type TEXT` - Type text (basic ASCII, handles shift automatically)

**Other:**
- `regions` - List available regions
- `help` - List available commands
- `quit` - Exit daemon

All commands output JSON responses:
```json
{"status":"ready","serial":2}
{"status":"ok","action":"move","x":768,"y":1200}
{"status":"ok","action":"click","x":500,"y":900}
{"status":"ok","action":"key","keycode":28}
{"status":"ok","action":"type","text":"Hello World"}
{"status":"ok","action":"regions","regions":[{"id":0,"x":1536,"y":700,"w":1707,"h":960,"scale":1.5},...]}
```

### Common Keycodes (Linux input-event-codes)

| Key | Code | Key | Code |
|-----|------|-----|------|
| Escape | 1 | Enter | 28 |
| Tab | 15 | Space | 57 |
| Backspace | 14 | Delete | 111 |
| Left Arrow | 105 | Right Arrow | 106 |
| Up Arrow | 103 | Down Arrow | 108 |
| Home | 102 | End | 107 |
| Page Up | 104 | Page Down | 109 |
| F1-F12 | 59-70 | Ctrl (L) | 29 |
| Shift (L) | 42 | Alt (L) | 56 |
| Super/Meta | 125 | | |

Letters: a=30, b=48, c=46, d=32, e=18, f=33, g=34, h=35, i=23, j=36, k=37, l=38, m=50, n=49, o=24, p=25, q=16, r=19, s=31, t=20, u=22, v=47, w=17, x=45, y=21, z=44

Numbers: 1=2, 2=3, 3=4, 4=5, 5=6, 6=7, 7=8, 8=9, 9=10, 0=11

## Coordinate System

EIS uses a regional coordinate system. Each monitor is a "region" with:
- `x`, `y` - Position in combined virtual space
- `width`, `height` - Logical size
- `scale` - Physical to logical scale factor

**Dell E2420H (AI monitor) - Region [1]:**
- X range: 0-1536
- Y range: 796-1660
- Scale: 1.25

To click at the center of the Dell monitor:
```bash
./target/release/portal-input eis-send -x 768 -y 1228 --click
```

## Using from Scripts

```bash
#!/bin/bash
# Example: Click center of Dell monitor

DAEMON_PID=""

start_daemon() {
    ./target/release/portal-input daemon &
    DAEMON_PID=$!
    # Wait for ready
    sleep 2
}

send_cmd() {
    echo "$1"
}

cleanup() {
    echo "quit"
    kill $DAEMON_PID 2>/dev/null
}

trap cleanup EXIT

start_daemon

# Send commands to stdin
send_cmd "move 768 1228"
sleep 0.1
send_cmd "click 768 1228"
sleep 0.1
send_cmd "quit"
```

## Limitations

1. **KDE Consent Dialog**: KDE's portal doesn't support persistent RemoteDesktop sessions, so each new invocation (except daemon mode) requires user consent.

2. **Daemon Mode**: Use daemon mode to avoid repeated consent dialogs. Start once, send multiple commands.

3. **Coordinates**: Must use EIS region coordinates, not physical screen pixels.

## Technical Details

- Uses `ashpd` crate for XDG portal communication
- Uses `reis` crate for EIS protocol
- Button codes: LEFT=272, RIGHT=273, MIDDLE=274

