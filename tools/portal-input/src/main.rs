//! Portal Input Controller
//! 
//! A CLI tool to send input via XDG RemoteDesktop portal.
//! This enables sending mouse/keyboard input to Wayland applications
//! without requiring focus - with user consent via portal dialog.

use ashpd::desktop::{
    remote_desktop::{DeviceType, KeyState, RemoteDesktop},
    screencast::{CursorMode, Screencast, SourceType},
    PersistMode,
};
use clap::{Parser, Subcommand};
use std::io::{self, BufRead, Write};

#[derive(Parser)]
#[command(name = "portal-input")]
#[command(about = "Send input via XDG RemoteDesktop portal")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Start interactive session
    Interactive,
    /// Quick test - shake cursor to verify input works
    Shake,
    /// Check portal availability
    Status,
}

#[tokio::main]
async fn main() -> ashpd::Result<()> {
    let cli = Cli::parse();
    
    match cli.command {
        Commands::Interactive => {
            run_interactive().await?;
        }
        Commands::Shake => {
            run_shake_test().await?;
        }
        Commands::Status => {
            let _rd = RemoteDesktop::new().await?;
            println!("✓ RemoteDesktop portal available");
            let _sc = Screencast::new().await?;
            println!("✓ Screencast portal available");
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
            false,  // single source
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
        for (i, stream) in streams.iter().enumerate() {
            println!("Stream {}: node={}, size={:?}", 
                i, stream.pipe_wire_node_id(), stream.size());
        }
    }
    println!();
    
    Ok((remote_desktop, session))
}

async fn run_shake_test() -> ashpd::Result<()> {
    let (remote_desktop, session) = create_session().await?;
    
    println!("=== Shake Test ===");
    println!("Shaking cursor rapidly...\n");
    
    // Shake back and forth
    for i in 0..10 {
        println!("Shake {}/10", i + 1);
        remote_desktop.notify_pointer_motion(&session, 100.0, 0.0).await?;
        tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
        remote_desktop.notify_pointer_motion(&session, -100.0, 0.0).await?;
        tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
    }
    
    println!("\nShake test complete!");
    tokio::time::sleep(tokio::time::Duration::from_secs(2)).await;
    
    Ok(())
}

async fn run_interactive() -> ashpd::Result<()> {
    let (remote_desktop, session) = create_session().await?;
    
    println!("=== Interactive Mode ===");
    println!("Commands:");
    println!("  move X Y    - Move pointer (absolute)");
    println!("  rel DX DY   - Move pointer (relative)");
    println!("  click       - Left click");
    println!("  rclick      - Right click");
    println!("  key CODE    - Keycode (28=Enter, 57=Space, 1=Esc)");
    println!("  shake       - Shake cursor");
    println!("  quit        - Exit\n");
    
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
                match remote_desktop.notify_pointer_motion_absolute(&session, 0, x, y).await {
                    Ok(_) => println!("Moved to ({}, {})", x, y),
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
                tokio::time::sleep(tokio::time::Duration::from_millis(50)).await;
                remote_desktop.notify_pointer_button(&session, 272, KeyState::Released).await?;
                println!("Clicked!");
            }
            "rclick" => {
                remote_desktop.notify_pointer_button(&session, 273, KeyState::Pressed).await?;
                tokio::time::sleep(tokio::time::Duration::from_millis(50)).await;
                remote_desktop.notify_pointer_button(&session, 273, KeyState::Released).await?;
                println!("Right-clicked!");
            }
            "key" if parts.len() >= 2 => {
                let keycode: i32 = parts[1].parse().unwrap_or(0);
                remote_desktop.notify_keyboard_keycode(&session, keycode, KeyState::Pressed).await?;
                tokio::time::sleep(tokio::time::Duration::from_millis(50)).await;
                remote_desktop.notify_keyboard_keycode(&session, keycode, KeyState::Released).await?;
                println!("Key {} sent", keycode);
            }
            "shake" => {
                println!("Shaking...");
                for _ in 0..5 {
                    remote_desktop.notify_pointer_motion(&session, 100.0, 0.0).await?;
                    tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
                    remote_desktop.notify_pointer_motion(&session, -100.0, 0.0).await?;
                    tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
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
