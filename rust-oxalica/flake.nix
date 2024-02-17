{
  description = "Basic template for nix + rust with rust toolchain provided by oxalica";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-23.11";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    rust-overlay,
  }: let
    inherit (nixpkgs) lib;
    systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];
    systemClosure = attrs:
      builtins.foldl' (acc: system:
        lib.recursiveUpdate acc (attrs system)) {}
      systems;
  in
    systemClosure (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (import rust-overlay)
            self.overlays.default
          ];
        };
        toolchain = pkgs.rust-bin.stable.latest.default;
        rustPlatform = pkgs.makeRustPlatform {
          rustc = toolchain;
          cargo = toolchain;
        };
        # Placeholder name allows one to enter `nix develop` prior to `Cargo.toml` existing
        name =
          if builtins.pathExists ./Cargo.toml
          then ((builtins.fromTOML (builtins.readFile ./Cargo.toml)).package).name
          else "placeholder";
      in {
        overlays = {
          default = self.overlays.${name};
          ${name} = _: prev: {
            # inherit doesn't work with dynamic attributes
            ${name} = self.packages.${prev.system}.${name};
          };
        };
        packages.${system} = {
          default = self.packages.${system}.${name};
          ${name} = rustPlatform.buildRustPackage {
            inherit name;
            version =
              if builtins.pathExists ./Cargo.toml
              then ((builtins.fromTOML (builtins.readFile ./Cargo.toml)).package).version
              else "placeholder";
            src = ./.;
            cargoLock.lockFile = ./Cargo.lock;
          };
        };

        apps.${system}.default = {
          type = "app";
          program = "${self.packages.${system}.${name}}/bin/${name}";
        };

        devShells.${system}.default = pkgs.mkShell {
          buildInputs = [toolchain];
        };
      }
    );
}
