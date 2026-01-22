{
  description = "Neongarten modding toolkit";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          name = "neongarten-mods";
          
          buildInputs = with pkgs; [
            # Reverse engineering
            # dnspy            # C# decompiler (for Unity DLLs)
            # Asset extraction
            # assetstudio      # Unity asset browser (not in nixpkgs yet)
            
            # Development
            python3
            python3Packages.pip
            python3Packages.pillow  # Image manipulation
            
            # 3D modeling pipeline
            blender
            
            # General utilities
            ripgrep
            fd
            jq
            
            # Game launching
            steam-run  # For running Windows games
          ];

          shellHook = ''
            echo "🌃 Neongarten Modding Environment"
            echo ""
            echo "Available tools:"
            echo "  blender        - 3D modeling"
            echo "  python         - Scripting"
            echo "  steam-run      - Run game with deps"
            echo ""
            echo "Project structure:"
            echo "  docs/          - Documentation"
            echo "  mods/          - Mod projects"
            echo "  tools/         - Development tools"
            echo "  assets/        - Art assets"
          '';
        };
      }
    );
}

