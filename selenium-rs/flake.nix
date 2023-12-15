{
  description = "Example selenium-rs application";

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
        inherit ((builtins.fromTOML (builtins.readFile ./Cargo.toml)).package) name;
      in {
        overlays = {
          default = self.overlays.${name};
          ${name} = _: prev: {
            # inherit doesn't work with dynamic attributes
            ${name} = (self.packages.${prev.system}).${name};
          };
        };
        packages.${system} = {
          default = self.packages.${system}.${name};
          ${name} = rustPlatform.buildRustPackage {
            inherit name;
            version = "0.0.1";
            src = ./.;
            cargoLock.lockFile = ./Cargo.lock;

            nativeBuildInputs = with pkgs; [
              makeBinaryWrapper
              darwin.apple_sdk.frameworks.Security
            ];
          };
        };

        devShells.${system}.default = pkgs.mkShell {
          buildInputs = [toolchain];
        };

        apps.${system}.default = let
          runner = pkgs.writeShellScriptBin "run" ''
            ${lib.getExe pkgs.geckodriver} &
            pid=$?
            ${self.outputs.packages.${system}.${name}}/bin/${name}
            kill $pid
          '';
        in {
          type = "app";
          program = "${runner}/bin/run";
        };
      }
    );
}
