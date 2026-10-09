{
  description = "VectorCraft: a native, open-source vector illustration editor written in Rust";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Upstream source. `flake = false` because the repo has no flake.nix of its own.
    # Pinned in flake.lock; `nix flake update vectorcraft-src` moves it to the latest commit.
    # To track a release instead: url = "github:storytold/vectorcraft/v0.7.0";
    vectorcraft-src = {
      url = "github:storytold/vectorcraft";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, vectorcraft-src }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: lib.genAttrs systems (system: f system nixpkgs.legacyPackages.${system});
      mkPackage = pkgs: pkgs.callPackage ./package.nix { src = vectorcraft-src; };
    in
    {
      packages = forAllSystems (
        _system: pkgs: rec {
          vectorcraft = mkPackage pkgs;
          default = vectorcraft;
        }
      );

      apps = forAllSystems (
        system: _pkgs: {
          default = {
            type = "app";
            program = lib.getExe self.packages.${system}.vectorcraft;
          };
          cli = {
            type = "app";
            program = "${self.packages.${system}.vectorcraft}/bin/vectorcraft-cli";
          };
        }
      );

      devShells = forAllSystems (
        system: pkgs: {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.vectorcraft ];
            packages = with pkgs; [
              rust-analyzer
              clippy
              rustfmt
            ];
            # Lets `cargo run -p vectorcraft` find the dlopen'd windowing/GPU libraries.
            LD_LIBRARY_PATH = lib.makeLibraryPath self.packages.${system}.vectorcraft.buildInputs;
          };
        }
      );

      # For `nixpkgs.overlays = [ vectorcraft.overlays.default ];`, giving `pkgs.vectorcraft`.
      overlays.default = final: _prev: {
        vectorcraft = mkPackage final;
      };
    };
}
