{
  description = "Basic template for nix + rust with rust toolchain provided by oxalica";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
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
      # Placeholder name allows one to enter `nix develop` prior to `Cargo.toml` existing
      name =
        if builtins.pathExists ./Cargo.toml then
          (fromTOML (builtins.readFile ./Cargo.toml)).package.name
        else
          "placeholder";
      systems = [
        "x86_64-darwin"
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      eachSystem =
        with nixpkgs.lib;
        f: foldAttrs mergeAttrs { } (map (s: mapAttrs (_: v: { ${s} = v; }) (f s)) systems);
    in
    eachSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };
        # toolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
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
            version =
              if builtins.pathExists ./Cargo.toml then
                (fromTOML (builtins.readFile ./Cargo.toml)).package.version
              else
                "placeholder";
            src = pkgs.lib.cleanSource ./.;
            cargoLock.lockFile = ./Cargo.lock;
          };
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.${name}}/bin/${name}";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            toolchain
          ]
          # ++ (with pkgs; [
          # avrdude
          # pkgsCross.avr.buildPackages.gcc
          # ravedude
          # ])
          ;
        };
      }
    );
}
