//! Portal Input Controller with EIS Support
//! 
//! Uses the XDG RemoteDesktop portal with EIS (Emulated Input System)
//! for proper input injection with correct coordinate handling.

use ashpd::desktop::{
    remote_desktop::{DeviceType, KeyState, RemoteDesktop},
    screencast::{CursorMode, Screencast, SourceType},
    PersistMode,
};
use clap::{Parser, Subcommand};
use std::io::{self, BufRead, Write};
use std::os::fd::AsRawFd;
use std::os::unix::net::UnixStream;
use std::time::{Duration, Instant};
use reis::handshake::EiHandshaker;
use reis::event::{EiEventConverter, EiEvent, DeviceCapability};

#[derive(Parser)]
#[command(name = "portal-input")]
#[command(about = "Send input via XDG RemoteDesktop portal (with EIS support)")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Interactive session with legacy notify methods
    Interactive,
    /// Test with EIS connection - full handshake and input test
    Eis,
    /// Send input via EIS to a specific region/coordinate
    EisSend {
        /// X coordinate within a region
        #[arg(short, long, default_value = "500")]
        x: f32,
        /// Y coordinate within a region
        #[arg(short, long, default_value = "500")]
        y: f32,
        /// Also click after moving
        #[arg(short, long)]
        click: bool,
        /// Shake the cursor for visibility
        #[arg(short, long)]
        shake: bool,
    },
    /// Quick shake test using legacy methods
    Shake,
    /// Check portal availability
    Status,
    /// Show coordinate system info
    Coords,
}

#[tokio::main]
async fn main() -> ashpd::Result<()> {
    let cli = Cli::parse();
    
    match cli.command {
        Commands::Interactive => run_interactive().await?,
        Commands::Eis => run_eis_test().await?,
        Commands::EisSend { x, y, click, shake } => run_eis_send(x, y, click, shake).await?,
        Commands::Shake => run_shake_test().await?,
        Commands::Status => {
            let rd = RemoteDesktop::new().await?;
            println!("✓ RemoteDesktop portal available");
            let device_types = rd.available_device_types().await?;
            println!("  Available devices: {:?}", device_types);
            let _sc = Screencast::new().await?;
            println!("✓ Screencast portal available");
        }
        Commands::Coords => {
            println!("Coordinate System Information:");
            println!("==============================");
            println!();
            println!("The portal uses these coordinate systems:");
            println!();
            println!("1. STREAM COORDINATES (notify_pointer_motion_absolute)");
            println!("   - X,Y relative to the captured stream's size");
            println!("   - Each stream has its own coordinate space");
            println!();
            println!("2. RELATIVE MOTION (notify_pointer_motion)");
            println!("   - DX,DY delta from current position");
            println!();
            println!("3. EIS REGIONS (via connect_to_eis)");
            println!("   - Compositor defines regions for each device");
            println!("   - Provides proper coordinate mapping");
            println!();
            println!("Run 'portal-input eis' to see actual regions from your session!");
        }
    }
    
    Ok(())
}

async fn create_session() -> ashpd::Result<(RemoteDesktop<'static>, ashpd::desktop::Session<'static, RemoteDesktop<'static>>)> {
    println!("=== Creating Portal Session ===\n");
    
    let remote_desktop = RemoteDesktop::new().await?;
    let screencast = Screencast::new().await?;
    
    let session = remote_desktop.create_session().await?;
    println!("✓ Session created");
    
    // Note: KDE doesn't support PersistMode for RemoteDesktop sessions,
    // so consent dialog will appear each time. Consider keeping session alive
    // for multiple operations.
    remote_desktop
        .select_devices(
            &session,
            DeviceType::Keyboard | DeviceType::Pointer,
            None,
            PersistMode::DoNot,
        )
        .await?;
    println!("✓ Devices selected (keyboard + pointer)");
    
    screencast
        .select_sources(
            &session,
            CursorMode::Embedded,
            SourceType::Monitor.into(),
            false,
            None,
            PersistMode::DoNot,
        )
        .await?;
    println!("✓ Screencast configured\n");
    
    println!("Waiting for consent dialog...");
    let response = remote_desktop.start(&session, None).await?.response()?;
    
    println!("\n✓ Session active!");
    println!("Devices: {:?}", response.devices());
    
    if let Some(streams) = response.streams() {
        println!("\nStream Information:");
        for (i, stream) in streams.iter().enumerate() {
            println!("  Stream {}: ", i);
            println!("    PipeWire Node: {}", stream.pipe_wire_node_id());
            if let Some(size) = stream.size() {
                println!("    Size: {}x{}", size.0, size.1);
            }
            if let Some(source_type) = stream.source_type() {
                println!("    Source Type: {:?}", source_type);
            }
        }
    }
    println!();
    
    Ok((remote_desktop, session))
}

async fn run_eis_test() -> ashpd::Result<()> {
    let (remote_desktop, session) = create_session().await?;
    
    println!("=== Connecting to EIS ===\n");
    
    // Get EIS file descriptor from portal
    match remote_desktop.connect_to_eis(&session).await {
        Ok(eis_fd) => {
            let raw_fd = eis_fd.as_raw_fd();
            println!("✓ EIS connection established (fd: {})", raw_fd);
            
            // Convert OwnedFd to UnixStream for reis
            let socket: UnixStream = eis_fd.into();
            // Set non-blocking for easier polling
            socket.set_nonblocking(true).ok();
            
            match reis::ei::Context::new(socket) {
                Ok(context) => {
                    println!("✓ reis context created");
                    
                    // Phase 1: Handshake
                    println!("\n--- EIS Handshake Phase ---");
                    let mut handshaker = EiHandshaker::new(
                        "portal-input",
                        reis::ei::handshake::ContextType::Sender,
                    );
                    
                    let mut handshake_complete = false;
                    let mut event_converter: Option<EiEventConverter> = None;
                    let timeout = Instant::now() + Duration::from_secs(10);
                    
                    while !handshake_complete && Instant::now() < timeout {
                        // Read data
                        match context.read() {
                            Ok(n) if n > 0 => println!("  Read {} bytes", n),
                            Err(e) if e.kind() != std::io::ErrorKind::WouldBlock => {
                                println!("  Read error: {:?}", e);
                                break;
                            }
                            _ => {}
                        }
                        
                        // Process events
                        while let Some(event_result) = context.pending_event() {
                            use reis::PendingRequestResult;
                            match event_result {
                                PendingRequestResult::Request(event) => {
                                    println!("  Event: {:?}", event);
                                    
                                    // Pass to handshaker
                                    match handshaker.handle_event(event) {
                                        Ok(Some(resp)) => {
                                            println!("\n✓ Handshake complete!");
                                            println!("  Serial: {}", resp.serial);
                                            println!("  Negotiated interfaces: {:?}", resp.negotiated_interfaces);
                                            
                                            // Create event converter for the next phase
                                            event_converter = Some(EiEventConverter::new(&context, resp));
                                            handshake_complete = true;
                                            break;
                                        }
                                        Ok(None) => {
                                            // Still waiting for more events
                                        }
                                        Err(e) => {
                                            println!("  Handshake error: {:?}", e);
                                            break;
                                        }
                                    }
                                }
                                PendingRequestResult::ParseError(e) => {
                                    println!("  Parse error: {:?}", e);
                                }
                                PendingRequestResult::InvalidObject(id) => {
                                    println!("  Invalid object ID: {}", id);
                                }
                            }
                        }
                        
                        std::thread::sleep(Duration::from_millis(50));
                    }
                    
                    if !handshake_complete {
                        println!("\n✗ Handshake timed out or failed");
                        return Ok(());
                    }
                    
                    // Phase 2: Wait for seat and devices
                    println!("\n--- Waiting for Seat/Devices ---");
                    let converter = event_converter.as_mut().unwrap();
                    let mut device_ready = false;
                    let timeout = Instant::now() + Duration::from_secs(10);
                    
                    while !device_ready && Instant::now() < timeout {
                        // Read data
                        match context.read() {
                            Ok(n) if n > 0 => println!("  Read {} bytes", n),
                            Err(e) if e.kind() != std::io::ErrorKind::WouldBlock => {
                                println!("  Read error: {:?}", e);
                                break;
                            }
                            _ => {}
                        }
                        
                        // Process events through converter
                        while let Some(event_result) = context.pending_event() {
                            use reis::PendingRequestResult;
                            match event_result {
                                PendingRequestResult::Request(event) => {
                                    match converter.handle_event(event) {
                                        Ok(()) => {
                                            // Check converter's event queue
                                            while let Some(ei_event) = converter.next_event() {
                                                println!("  EiEvent: {:?}", ei_event);
                                                
                                                match ei_event {
                                                    EiEvent::SeatAdded(seat_added) => {
                                                        println!("\n✓ Seat added: {:?}", seat_added.seat);
                                                        // Bind to all capabilities we want
                                                        println!("  Requesting capabilities...");
                                                        seat_added.seat.bind_capabilities(&[
                                                            DeviceCapability::Pointer,
                                                            DeviceCapability::PointerAbsolute,
                                                            DeviceCapability::Button,
                                                            DeviceCapability::Keyboard,
                                                            DeviceCapability::Scroll,
                                                        ]);
                                                        // Flush the request
                                                        converter.connection().flush().ok();
                                                        println!("  ✓ Capabilities bound");
                                                    }
                                                    EiEvent::DeviceAdded(device_added) => {
                                                        println!("\n✓ Device added: {:?}", device_added.device);
                                                        println!("  Name: {:?}", device_added.device.name());
                                                        println!("  Type: {:?}", device_added.device.device_type());
                                                        println!("  Dimensions: {:?}", device_added.device.dimensions());
                                                        println!("  Regions: {:?}", device_added.device.regions());
                                                        
                                                        // Check capabilities
                                                        if device_added.device.has_capability(reis::event::DeviceCapability::PointerAbsolute) {
                                                            println!("  ✓ Has PointerAbsolute capability");
                                                            device_ready = true;
                                                        }
                                                        if device_added.device.has_capability(reis::event::DeviceCapability::Pointer) {
                                                            println!("  ✓ Has Pointer (relative) capability");
                                                        }
                                                        if device_added.device.has_capability(reis::event::DeviceCapability::Button) {
                                                            println!("  ✓ Has Button capability");
                                                        }
                                                        if device_added.device.has_capability(reis::event::DeviceCapability::Keyboard) {
                                                            println!("  ✓ Has Keyboard capability");
                                                        }
                                                    }
                                                    _ => {}
                                                }
                                            }
                                        }
                                        Err(e) => {
                                            println!("  Event converter error: {:?}", e);
                                        }
                                    }
                                }
                                PendingRequestResult::ParseError(e) => {
                                    println!("  Parse error: {:?}", e);
                                }
                                PendingRequestResult::InvalidObject(id) => {
                                    println!("  Invalid object ID: {}", id);
                                }
                            }
                        }
                        
                        std::thread::sleep(Duration::from_millis(50));
                    }
                    
                    if device_ready {
                        println!("\n=== EIS Ready for Input! ===");
                        println!("\nTo send input through EIS:");
                        println!("1. Get the device's PointerAbsolute interface");
                        println!("2. Call device.start_emulating(serial, sequence)");
                        println!("3. Call pointer_absolute.motion_absolute(x, y)");
                        println!("4. Call device.frame(serial, timestamp)");
                        println!("5. Call device.stop_emulating(serial)");
                    } else {
                        println!("\n✗ Timed out waiting for devices");
                    }
                }
                Err(e) => {
                    println!("Failed to create reis context: {:?}", e);
                }
            }
        }
        Err(e) => {
            println!("✗ Failed to connect to EIS: {:?}", e);
            println!("\nNote: EIS might not be supported yet.");
        }
    }
    
    println!("\nSession will close in 3 seconds...");
    tokio::time::sleep(Duration::from_secs(3)).await;
    
    Ok(())
}

async fn run_eis_send(x: f32, y: f32, click: bool, shake: bool) -> ashpd::Result<()> {
    let (remote_desktop, session) = create_session().await?;
    
    println!("=== EIS Input Test ===\n");
    println!("Target: ({}, {})", x, y);
    if click { println!("Will click after moving"); }
    if shake { println!("Will shake cursor"); }
    
    // Connect to EIS
    let eis_fd = remote_desktop.connect_to_eis(&session).await?;
    println!("\n✓ EIS connected (fd: {})", eis_fd.as_raw_fd());
    
    let socket: UnixStream = eis_fd.into();
    socket.set_nonblocking(true).ok();
    
    let context = reis::ei::Context::new(socket).expect("Failed to create reis context");
    println!("✓ reis context created");
    
    // Handshake
    println!("\n--- Handshake ---");
    let mut handshaker = EiHandshaker::new("portal-input", reis::ei::handshake::ContextType::Sender);
    let mut event_converter: Option<EiEventConverter> = None;
    let timeout = Instant::now() + Duration::from_secs(5);
    
    'handshake: while Instant::now() < timeout {
        context.read().ok();
        while let Some(event_result) = context.pending_event() {
            if let reis::PendingRequestResult::Request(event) = event_result {
                if let Ok(Some(resp)) = handshaker.handle_event(event) {
                    println!("✓ Handshake complete (serial: {})", resp.serial);
                    event_converter = Some(EiEventConverter::new(&context, resp));
                    break 'handshake;
                }
            }
        }
        std::thread::sleep(Duration::from_millis(20));
    }
    
    let converter = event_converter.as_mut().expect("Handshake failed");
    
    // Wait for seat and bind capabilities
    println!("\n--- Device Setup ---");
    let mut abs_device: Option<reis::event::Device> = None;
    let mut serial = 0u32;
    let timeout = Instant::now() + Duration::from_secs(5);
    
    'setup: while Instant::now() < timeout {
        context.read().ok();
        while let Some(event_result) = context.pending_event() {
            if let reis::PendingRequestResult::Request(event) = event_result {
                if converter.handle_event(event).is_ok() {
                    while let Some(ei_event) = converter.next_event() {
                        match ei_event {
                            EiEvent::SeatAdded(seat_added) => {
                                println!("✓ Seat: {:?}", seat_added.seat);
                                seat_added.seat.bind_capabilities(&[
                                    DeviceCapability::Pointer,
                                    DeviceCapability::PointerAbsolute,
                                    DeviceCapability::Button,
                                ]);
                                converter.connection().flush().ok();
                                println!("  ✓ Bound capabilities");
                            }
                            EiEvent::DeviceAdded(device_added) => {
                                if device_added.device.has_capability(DeviceCapability::PointerAbsolute) {
                                    println!("✓ Absolute device: {:?}", device_added.device.name());
                                    println!("  Regions:");
                                    for (i, region) in device_added.device.regions().iter().enumerate() {
                                        println!("    [{}] x:{}, y:{}, {}x{} @ scale {}", 
                                            i, region.x, region.y, region.width, region.height, region.scale);
                                    }
                                    abs_device = Some(device_added.device.clone());
                                }
                            }
                            EiEvent::DeviceResumed(resumed) => {
                                println!("✓ Device resumed (serial: {})", resumed.serial);
                                serial = resumed.serial;
                                if abs_device.is_some() {
                                    break 'setup;
                                }
                            }
                            _ => {}
                        }
                    }
                }
            }
        }
        std::thread::sleep(Duration::from_millis(20));
    }
    
    let device = abs_device.expect("No absolute device found");
    
    // Get interfaces
    let pointer_abs: reis::ei::PointerAbsolute = device.interface()
        .expect("Device should have PointerAbsolute");
    let button_iface: Option<reis::ei::Button> = device.interface();
    let ei_device = device.device();
    
    println!("\n=== Sending EIS Input ===\n");
    
    // Start emulating
    let mut sequence = 1u32;
    ei_device.start_emulating(serial, sequence);
    context.flush().ok();
    println!("✓ Started emulating (seq: {})", sequence);
    
    // Get current time for frames
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_micros() as u64;
    
    if shake {
        // Shake cursor to make it visible
        println!("\n--- Shaking cursor ---");
        for i in 0..5 {
            // Move right
            pointer_abs.motion_absolute(x + (i as f32 + 1.0) * 50.0, y);
            serial += 1;
            ei_device.frame(serial, now + i as u64 * 100_000);
            context.flush().ok();
            std::thread::sleep(Duration::from_millis(100));
            
            // Move back
            pointer_abs.motion_absolute(x, y);
            serial += 1;
            ei_device.frame(serial, now + i as u64 * 100_000 + 50_000);
            context.flush().ok();
            std::thread::sleep(Duration::from_millis(100));
        }
        println!("✓ Shake complete");
    }
    
    // Move to target
    println!("\n--- Moving to ({}, {}) ---", x, y);
    pointer_abs.motion_absolute(x, y);
    serial += 1;
    ei_device.frame(serial, now + 500_000);
    context.flush().ok();
    println!("✓ Moved to ({}, {})", x, y);
    
    if click {
        if let Some(ref button) = button_iface {
            std::thread::sleep(Duration::from_millis(100));
            
            // Left click (BTN_LEFT = 0x110 = 272)
            println!("\n--- Clicking ---");
            button.button(272, reis::ei::button::ButtonState::Press);
            serial += 1;
            ei_device.frame(serial, now + 600_000);
            context.flush().ok();
            
            std::thread::sleep(Duration::from_millis(50));
            
            button.button(272, reis::ei::button::ButtonState::Released);
            serial += 1;
            ei_device.frame(serial, now + 650_000);
            context.flush().ok();
            
            println!("✓ Clicked!");
        } else {
            println!("✗ No button interface available");
        }
    }
    
    // Stop emulating
    std::thread::sleep(Duration::from_millis(100));
    sequence += 1;
    ei_device.stop_emulating(serial);
    context.flush().ok();
    println!("\n✓ Stopped emulating");
    
    // Keep session alive briefly to ensure input is processed
    println!("\nHolding session for 2 seconds...");
    tokio::time::sleep(Duration::from_secs(2)).await;
    
    println!("Done!");
    Ok(())
}

async fn run_shake_test() -> ashpd::Result<()> {
    let (remote_desktop, session) = create_session().await?;
    
    println!("=== Shake Test (Relative Motion) ===\n");
    
    for i in 0..10 {
        println!("Shake {}/10", i + 1);
        remote_desktop.notify_pointer_motion(&session, 100.0, 0.0).await?;
        tokio::time::sleep(Duration::from_millis(100)).await;
        remote_desktop.notify_pointer_motion(&session, -100.0, 0.0).await?;
        tokio::time::sleep(Duration::from_millis(100)).await;
    }
    
    println!("\n✓ Shake complete!");
    tokio::time::sleep(Duration::from_secs(2)).await;
    
    Ok(())
}

async fn run_interactive() -> ashpd::Result<()> {
    let (remote_desktop, session) = create_session().await?;
    
    println!("=== Interactive Mode ===");
    println!("Commands:");
    println!("  move X Y [STREAM]  - Absolute move (default stream 0)");
    println!("  rel DX DY          - Relative move");
    println!("  click              - Left click");
    println!("  rclick             - Right click");
    println!("  key CODE           - Keycode (28=Enter, 57=Space)");
    println!("  shake              - Shake cursor");
    println!("  quit               - Exit\n");
    
    let stdin = io::stdin();
    let mut stdout = io::stdout();
    
    loop {
        print!("> ");
        stdout.flush().unwrap();
        
        let mut line = String::new();
        if stdin.lock().read_line(&mut line).is_err() {
            break;
        }
        let parts: Vec<&str> = line.trim().split_whitespace().collect();
        
        if parts.is_empty() {
            continue;
        }
        
        match parts[0] {
            "move" if parts.len() >= 3 => {
                let x: f64 = parts[1].parse().unwrap_or(0.0);
                let y: f64 = parts[2].parse().unwrap_or(0.0);
                let stream: u32 = parts.get(3).and_then(|s| s.parse().ok()).unwrap_or(0);
                match remote_desktop.notify_pointer_motion_absolute(&session, stream, x, y).await {
                    Ok(_) => println!("Moved to ({}, {}) on stream {}", x, y, stream),
                    Err(e) => println!("Error: {}", e),
                }
            }
            "rel" if parts.len() >= 3 => {
                let dx: f64 = parts[1].parse().unwrap_or(0.0);
                let dy: f64 = parts[2].parse().unwrap_or(0.0);
                match remote_desktop.notify_pointer_motion(&session, dx, dy).await {
                    Ok(_) => println!("Moved by ({}, {})", dx, dy),
                    Err(e) => println!("Error: {}", e),
                }
            }
            "click" => {
                remote_desktop.notify_pointer_button(&session, 272, KeyState::Pressed).await?;
                tokio::time::sleep(Duration::from_millis(50)).await;
                remote_desktop.notify_pointer_button(&session, 272, KeyState::Released).await?;
                println!("Clicked!");
            }
            "rclick" => {
                remote_desktop.notify_pointer_button(&session, 273, KeyState::Pressed).await?;
                tokio::time::sleep(Duration::from_millis(50)).await;
                remote_desktop.notify_pointer_button(&session, 273, KeyState::Released).await?;
                println!("Right-clicked!");
            }
            "key" if parts.len() >= 2 => {
                let keycode: i32 = parts[1].parse().unwrap_or(0);
                remote_desktop.notify_keyboard_keycode(&session, keycode, KeyState::Pressed).await?;
                tokio::time::sleep(Duration::from_millis(50)).await;
                remote_desktop.notify_keyboard_keycode(&session, keycode, KeyState::Released).await?;
                println!("Key {} sent", keycode);
            }
            "shake" => {
                println!("Shaking...");
                for _ in 0..5 {
                    remote_desktop.notify_pointer_motion(&session, 100.0, 0.0).await?;
                    tokio::time::sleep(Duration::from_millis(100)).await;
                    remote_desktop.notify_pointer_motion(&session, -100.0, 0.0).await?;
                    tokio::time::sleep(Duration::from_millis(100)).await;
                }
                println!("Done!");
            }
            "quit" | "exit" | "q" => {
                println!("Closing session...");
                break;
            }
            _ => println!("Unknown: {}", parts[0]),
        }
    }
    
    Ok(())
}

