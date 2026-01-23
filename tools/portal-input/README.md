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
- `move X Y` - Move cursor to absolute position
- `click X Y` - Move and left-click
- `rclick X Y` - Move and right-click
- `regions` - List available regions
- `quit` - Exit daemon

All commands output JSON responses:
```json
{"status":"ready","serial":2}
{"status":"ok","action":"move","x":768,"y":1200}
{"status":"ok","action":"click","x":500,"y":900}
{"status":"ok","action":"regions","regions":[{"id":0,"x":1536,"y":700,"w":1707,"h":960,"scale":1.5},...]}
```

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

