{
  description = "Basic template for nix + rust";

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
          overlays = [(import rust-overlay)];
        };
        toolchain = pkgs.rust-bin.stable.latest.default;
        rustPlatform = pkgs.makeRustPlatform {
          rustc = toolchain;
          cargo = toolchain;
        };
        inherit ((builtins.fromTOML (builtins.readFile ./Cargo.toml)).package) name;
      in {
        packages.${system} = {
          default = self.packages.${system}.${name};
          ${name} = rustPlatform.buildRustPackage {
            inherit name;
            version = "0.0.1";
            src = ./.;
            cargoLock.lockFile = ./Cargo.lock;
          };
        };

        devShells.${system}.default = pkgs.mkShell {
          buildInputs = [toolchain];
        };
      }
    );
}
