# Godot Interaction Harness

A lightweight CLI toolkit for AI agents to interact with Godot projects **without** burning tokens on slow GUI automation frameworks like Playwright.

## Philosophy

- **Token-efficient**: Returns JSON, no screenshots unless explicitly needed
- **Fast**: CLI-first, headless operations where possible
- **Scriptable**: All operations are composable shell commands
- **Project-aware**: Understands Godot project structure

## Quick Start

```bash
# Get project info
./gdharness info

# List all building structures with their properties
./gdharness list-structures | jq '.structures[] | select(.rarity == 2)'

# List all scenes
./gdharness list-scenes

# Screenshot the Godot editor window
./gdharness screenshot /tmp/godot.png

# Run a custom GDScript headlessly
./gdharness run scripts/my_script.gd
```

## Commands

### `gdharness info`
Returns project metadata as JSON:
```json
{
  "name": "Neongarten",
  "version": "Unknown",
  "features": "4.5 Forward Plus",
  "path": "/path/to/recovered",
  "counts": {"scenes": 123, "scripts": 51, "resources": 172}
}
```

### `gdharness list-structures`
Lists all building/structure .tres files with extracted properties:
```json
{
  "command": "list-structures",
  "structures": [
    {"name": "bar", "path": "structures/bar.tres", "rarity": 0, "legality": 0, "income": 1},
    ...
  ]
}
```

**Property mappings:**
- `rarity`: 0=Common, 1=Uncommon, 2=Rare
- `legality`: 0=Neutral, 1=Illegal, 2=Corp, 3=Volt, 4=Govt

### `gdharness list-scenes`
Lists all .tscn files in the project.

### `gdharness list-scripts`
Lists all .gd files in the project.

### `gdharness list-resources [pattern]`
Lists resources matching glob pattern (default: `*.tres`).

### `gdharness screenshot [output.png]`
Captures the Godot editor window (Wayland/X11 aware).

### `gdharness validate`
Runs Godot's parser to check for script errors.

### `gdharness run <script.gd> [args]`
Executes a GDScript file in headless mode.

### `gdharness query <expression>`
Evaluates a GDScript expression and returns the result.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GODOT_PROJECT` | `./recovered` | Path to Godot project |
| `GODOT_BIN` | `godot` | Godot executable |

## Integration with AI Workflows

### Analyzing Buildings
```bash
# Find all rare illegal buildings
./gdharness list-structures | jq '.structures[] | select(.rarity == 2 and .legality == 1)'

# Count buildings by faction
./gdharness list-structures | jq '.structures | group_by(.legality) | map({legality: .[0].legality, count: length})'
```

### Modding Workflow
```bash
# 1. Extract building data
./gdharness list-structures > buildings.json

# 2. Modify values in JSON
jq '.structures[] | select(.name == "bar") | .income = 5' buildings.json

# 3. Apply changes via custom script
./gdharness run mods/apply_changes.gd buildings.json
```

## Screenshot Tool (`gshot`)

Standalone screenshot utility:
```bash
./gshot /tmp/godot.png
# Returns: {"success":true,"path":"/tmp/godot.png","method":"spectacle","size":123456}
```

Supports:
- **Wayland**: spectacle (KDE), grim (wlroots)
- **X11**: import (ImageMagick), scrot

## NixOS Notes

On NixOS, ensure required tools are in your environment:
```nix
# In flake.nix devShell
buildInputs = [
  pkgs.jq
  pkgs.spectacle  # KDE Wayland
  pkgs.grim       # wlroots Wayland
  pkgs.imagemagick  # X11
  pkgs.xdotool    # X11 window finding
];
```

