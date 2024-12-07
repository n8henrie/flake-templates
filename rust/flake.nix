{
  description = "Basic template for nix + rust";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs =
    { self, nixpkgs }:
    let
      # Placeholder name allows one to enter `nix develop` prior to `Cargo.toml` existing
      pname =
        if builtins.pathExists ./Cargo.toml then
          (builtins.fromTOML (builtins.readFile ./Cargo.toml)).package.name
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
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = {
          default = self.packages.${system}.${pname};
          ${pname} = pkgs.callPackage ./. { inherit pname; };
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.${pname}}/bin/${pname}";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            cargo
            cargo-watch
            rust-analyzer
            rustfmt
          ];
        };
      }
    );
}
