{
  description = "Minimal dev shell for uv + pygame on NixOS (no nix-ld needed)";

  # inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
      lib = pkgs.lib;

      # Libraries pygame/SDL commonly need at runtime
      runtimeLibs = with pkgs; [
        stdenv.cc.cc # libc, libstdc++
        zlib
        libGL
        libGLU
        mesa # GL drivers (software fallback etc.)
        xorg.libX11
        xorg.libXext
        xorg.libXcursor
        xorg.libXrandr
        xorg.libXrender
        xorg.libXi
        xorg.libXinerama
        libxkbcommon
        wayland # if you’re on Wayland
        alsa-lib
        pulseaudio
        SDL2
        SDL2_image
        SDL2_mixer
        SDL2_ttf
        libjpeg_turbo
        libpng
        freetype
        # Optional but nice to have:
        libvorbis
        libogg
        libmad
      ];
    in {
      devShells.default = pkgs.mkShell {
        packages = with pkgs;
          [
            uv
            python312 # we’ll make uv use THIS python
            pkg-config # helps when wheels fall back to building
          ]
          ++ runtimeLibs;

        # Make the native libs visible to Python extensions / SDL.
        # (This keeps things working even if a manylinux wheel is used.)
        LD_LIBRARY_PATH = lib.makeLibraryPath runtimeLibs;

        # Quality-of-life: Wayland/X11 toggles and SDL hints
        SDL_AUDIODRIVER = "pulseaudio";
        # If you hit Wayland quirks, uncomment the next line to force X11:
        # SDL_VIDEODRIVER = "x11";

        shellHook = ''
          echo ""
          echo "⭐  UV + Pygame shell ready."
          echo ""
          echo "Use the Nix python so we don't need nix-ld:"
          echo "  uv venv --python \"$(command -v python3)\""
          echo "  uv add pygame"
          echo "  uv run python -m pygame.examples.aliens"
          echo ""
          echo "If windowing/audio complain, try:"
          echo "  SDL_VIDEODRIVER=x11 uv run python your_game.py"
          echo ""
        '';
      };
    });
}
