{
  description = "Neongarten modding toolkit - Godot 4.3 reverse engineering and mod development";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Game paths for reference
        steamPath = "$HOME/.local/share/Steam/steamapps/common/Neongarten";
        
      in {
        devShells.default = pkgs.mkShell {
          name = "neongarten-mods";
          
          buildInputs = with pkgs; [
            # ═══════════════════════════════════════════════════════════════
            # GODOT ENGINE & TOOLS (Game is Godot 4.3.0)
            # ═══════════════════════════════════════════════════════════════
            godot_4                    # Godot 4 editor for creating mods
            godotpcktool               # PCK extraction/creation (critical!)
            gdtoolkit                  # GDScript linter, formatter, parser
            gdscript-formatter         # Fast GDScript formatter
            
            # ═══════════════════════════════════════════════════════════════
            # REVERSE ENGINEERING
            # ═══════════════════════════════════════════════════════════════
            # gdsdecomp - Needs manual download from GitHub releases
            # https://github.com/GDRETools/gdsdecomp/releases
            
            # Binary analysis
            binutils                   # strings, objdump, etc.
            hexyl                      # Beautiful hex viewer
            xxd                        # Hex dump utility
            
            # ═══════════════════════════════════════════════════════════════
            # 3D MODELING PIPELINE (For Evie)
            # ═══════════════════════════════════════════════════════════════
            blender                    # 3D modeling (GLB/GLTF export)
            # Game uses GLB format for models
            
            # ═══════════════════════════════════════════════════════════════
            # IMAGE & ASSET TOOLS
            # ═══════════════════════════════════════════════════════════════
            imagemagick                # Image conversion
            gimp                       # Texture editing
            inkscape                   # SVG/vector work
            
            # ═══════════════════════════════════════════════════════════════
            # SCRIPTING & DEVELOPMENT
            # ═══════════════════════════════════════════════════════════════
            python3
            python3Packages.pip
            python3Packages.pillow     # Image manipulation
            python3Packages.pyyaml     # YAML parsing
            
            # ═══════════════════════════════════════════════════════════════
            # GENERAL UTILITIES
            # ═══════════════════════════════════════════════════════════════
            ripgrep                    # Fast text search
            fd                         # Fast file finder
            jq                         # JSON processing
            yq                         # YAML processing
            tree                       # Directory visualization
            bat                        # Better cat
            
            # ═══════════════════════════════════════════════════════════════
            # GAME LAUNCHING (Linux/Proton)
            # ═══════════════════════════════════════════════════════════════
            steam-run                  # Run game/tools with Steam runtime
          ];

          shellHook = ''
            echo ""
            echo "╔══════════════════════════════════════════════════════════════╗"
            echo "║     🌃 NEONGARTEN MODDING ENVIRONMENT                        ║"
            echo "║     Game Engine: Godot 4.3.0                                 ║"
            echo "╚══════════════════════════════════════════════════════════════╝"
            echo ""
            echo "📍 Game Location: ${steamPath}"
            echo ""
            echo "🛠️  Available Tools:"
            echo "  godot              - Godot 4 editor"
            echo "  godotpcktool       - PCK extraction/creation"
            echo "  gdformat           - GDScript formatter"
            echo "  gdlint             - GDScript linter"
            echo "  blender            - 3D modeling"
            echo ""
            echo "📋 Quick Commands:"
            echo "  # List PCK contents"
            echo "  godotpcktool -p <pck> -a list"
            echo ""
            echo "  # Extract PCK to directory"
            echo "  godotpcktool -p <pck> -a extract -o ./extracted"
            echo ""
            echo "  # Create PCK from directory"
            echo "  godotpcktool -p output.pck -a add -f ./modded --set-godot-version 4.3.0"
            echo ""
            echo "📖 Documentation:"
            echo "  docs/TECHNICAL_RESEARCH.md  - Engine & format research"
            echo "  docs/GAME_ANALYSIS.md       - Gameplay mechanics"
            echo "  docs/ART_GUIDELINES.md      - Asset creation guide"
            echo ""
            echo "⚠️  Note: For full decompilation, download gdsdecomp from:"
            echo "    https://github.com/GDRETools/gdsdecomp/releases"
            echo ""
            
            # Set up convenient aliases
            alias pck-list='godotpcktool -a list -p'
            alias pck-extract='godotpcktool -a extract -p'
            
            # Export game path
            export NEONGARTEN_PATH="${steamPath}"
          '';
        };
        
        # Package for tools
        packages = {
          # Helper script for common operations
          ng-tools = pkgs.writeShellScriptBin "ng-tools" ''
            #!/usr/bin/env bash
            set -euo pipefail
            
            GAME_PATH="$HOME/.local/share/Steam/steamapps/common/Neongarten"
            MAIN_PCK="$GAME_PATH/Neongarten.pck"
            PROLOGUE_PCK="$GAME_PATH/NeongartenPrologue.pck"
            
            case "''${1:-help}" in
              list)
                echo "Listing main PCK contents..."
                ${pkgs.godotpcktool}/bin/godotpcktool -p "$MAIN_PCK" -a list
                ;;
              extract)
                OUTPUT="''${2:-./extracted/main}"
                echo "Extracting to $OUTPUT..."
                mkdir -p "$OUTPUT"
                ${pkgs.godotpcktool}/bin/godotpcktool -p "$MAIN_PCK" -a extract -o "$OUTPUT"
                ;;
              strings)
                FILE="''${2:-}"
                if [ -z "$FILE" ]; then
                  echo "Usage: ng-tools strings <file.res>"
                  exit 1
                fi
                ${pkgs.binutils}/bin/strings "$FILE"
                ;;
              hex)
                FILE="''${2:-}"
                if [ -z "$FILE" ]; then
                  echo "Usage: ng-tools hex <file>"
                  exit 1
                fi
                ${pkgs.hexyl}/bin/hexyl "$FILE" | head -100
                ;;
              *)
                echo "Neongarten Modding Tools"
                echo ""
                echo "Usage: ng-tools <command> [args]"
                echo ""
                echo "Commands:"
                echo "  list              List main PCK contents"
                echo "  extract [dir]     Extract main PCK to directory"
                echo "  strings <file>    Extract strings from binary file"
                echo "  hex <file>        Hex dump file"
                ;;
            esac
          '';
        };
      }
    );
}
