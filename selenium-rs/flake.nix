{
  description = "Example selenium-rs application";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
    }:
    let
      inherit (nixpkgs) lib;
      inherit ((builtins.fromTOML (builtins.readFile ./Cargo.toml)).package) name;
      systems = [
        "x86_64-darwin"
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      eachSystem =
        with lib;
        f: foldAttrs mergeAttrs { } (map (s: mapAttrs (_: v: { ${s} = v; }) (f s)) systems);
    in
    eachSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };
        toolchain = pkgs.rust-bin.stable.latest.default;
        rustPlatform = pkgs.makeRustPlatform {
          rustc = toolchain;
          cargo = toolchain;
        };
      in
      {
        packages = {
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

        devShells.default = pkgs.mkShell { buildInputs = [ toolchain ]; };

        apps.default =
          let
            runner = pkgs.writeShellScriptBin "run" ''
              ${lib.getExe pkgs.geckodriver} &
              pid=$?
              ${self.outputs.packages.${system}.${name}}/bin/${name}
              kill $pid
            '';
          in
          {
            type = "app";
            program = "${runner}/bin/run";
          };
      }
    );
}
