# Wayland Input Workarounds for Unfocused Interaction

**Status**: ✅ WORKING - EIS via Portal implemented successfully!

This document explores potential solutions and our successful implementation to bypass Wayland's security model, which prevents sending synthetic input to unfocused windows.

## ✅ SOLUTION: XDG Desktop Portal + EIS

**This approach is working and recommended.**

### Implementation

We successfully implemented unfocused input using:

1. **XDG Desktop Portal** - `org.freedesktop.portal.RemoteDesktop`
2. **EIS (Emulated Input System)** - `libei` protocol via `reis` Rust crate
3. **ashpd** - Async XDG portal client for Rust

### How It Works

```
┌─────────────────────────────────────────────────┐
│ Portal Request Flow                              │
│                                                  │
│ 1. RemoteDesktop.create_session()               │
│ 2. RemoteDesktop.select_devices(keyboard+ptr)   │
│ 3. Screencast.select_sources(monitors)          │
│ 4. RemoteDesktop.start() → User consent dialog  │
│ 5. RemoteDesktop.connect_to_eis() → Socket FD   │
│                                                  │
│ EIS Handshake Flow                               │
│                                                  │
│ 6. Send handshake_version, name, context_type   │
│ 7. Negotiate interfaces (pointer_absolute, etc) │
│ 8. Receive Connection event                     │
│ 9. Receive SeatAdded event                      │
│ 10. Call seat.bind_capabilities()               │
│ 11. Receive DeviceAdded event(s)                │
│ 12. Receive DeviceResumed event                 │
│                                                  │
│ Input Injection                                  │
│                                                  │
│ 13. device.start_emulating(serial, seq)         │
│ 14. pointer_abs.motion_absolute(x, y)           │
│ 15. button.button(272, Press/Released)          │
│ 16. device.frame(serial, timestamp)             │
│ 17. device.stop_emulating(serial)               │
└─────────────────────────────────────────────────┘
```

### Tool: `portal-input`

Location: `tools/portal-input/`

```bash
# Build
cargo build --release

# Test EIS connection and see regions
cargo run -- eis

# Send input (move cursor)
cargo run -- eis-send -x 768 -y 1200

# Send input (move and click)
cargo run -- eis-send -x 768 -y 1200 --click

# Send input (shake for visibility)
cargo run -- eis-send -x 768 -y 1200 --shake
```

### EIS Coordinates

EIS uses a regional coordinate system where each monitor/output is a "region" with:
- `x`, `y` - Position in combined virtual space
- `width`, `height` - Logical size
- `scale` - Physical to logical scale factor

**Example regions (current system):**
```
[0] x:1536, y:700, 1707x960 @ scale 1.5  - Main monitor
[1] x:0, y:796, 1536x864 @ scale 1.25    - Dell (AI monitor)
```

To target a position on the Dell monitor:
- X: 0-1536 (center = 768)
- Y: 796-1660 (center = 1228)

### Limitations

1. **No Session Persistence**: KDE doesn't support persistent RemoteDesktop sessions
   - Each `portal-input` invocation shows consent dialog
   - Workaround: Daemon mode (future implementation)

2. **Coordinate System**: Requires understanding of EIS regions
   - Must map physical screen positions to EIS coordinates
   - Regions have offsets and scale factors

## Alternative Approaches (Not Implemented)

### Nested Compositors

Running Godot inside `gamescope` or `cage` provides full control:

```bash
# gamescope - runs app in isolated Wayland session
gamescope -W 1920 -H 1080 -- godot --editor ~/neongarten-mods/recovered/
```

**Pros**: Full input control within the nested session
**Cons**: Additional complexity, need to inject input into nested compositor

### VNC (wayvnc)

```bash
# Start VNC server on Wayland
wayvnc 0.0.0.0 5900
```

**Pros**: Full remote control
**Cons**: Network overhead, extra setup

### Direct Tools (Require Focus)

- **ydotool**: Generic input simulation, requires focus
- **kdotool**: KDE-specific xdotool clone, requires focus

These don't work for unfocused interaction on Wayland.

## Key Libraries

### ashpd (Rust)
- Async XDG Desktop Portal client
- Handles D-Bus communication
- Portal session management

```rust
let remote_desktop = RemoteDesktop::new().await?;
let session = remote_desktop.create_session().await?;
remote_desktop.select_devices(&session, DeviceType::Keyboard | DeviceType::Pointer, None, PersistMode::DoNot).await?;
```

### reis (Rust)
- Pure Rust EIS/libeis protocol implementation
- Handles EIS handshake and event processing
- Provides device interfaces for input injection

```rust
let context = reis::ei::Context::new(socket)?;
let mut handshaker = EiHandshaker::new("my-app", ContextType::Sender);
// ... handle events ...
let pointer_abs: PointerAbsolute = device.interface().unwrap();
pointer_abs.motion_absolute(x, y);
```

## Button Codes

Linux input-event-codes.h button values:

| Button | Code | Hex |
|--------|------|-----|
| BTN_LEFT | 272 | 0x110 |
| BTN_RIGHT | 273 | 0x111 |
| BTN_MIDDLE | 274 | 0x112 |

## References

- [XDG Desktop Portal Spec](https://flatpak.github.io/xdg-desktop-portal/)
- [libei/libeis](https://gitlab.freedesktop.org/libinput/libei)
- [reis crate](https://crates.io/crates/reis)
- [ashpd crate](https://crates.io/crates/ashpd)
- [input-event-codes.h](https://github.com/torvalds/linux/blob/master/include/uapi/linux/input-event-codes.h)
