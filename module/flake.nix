{
  description = "A very basic flake for a package";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      name = "";
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
    (
      eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          packages = {
            default = self.packages.${system}.${name};
            ${name} = pkgs.callPackage ./package.nix { inherit name; };
          };

          apps.default = {
            type = "app";
            program = "${pkgs.lib.getExe self.packages.${system}.default}";
          };

          devShells.default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.default ];
          };
        }
      )
      // {
        nixosModules = {
          default = self.outputs.nixosModules.${name};
          ${name} = import ./module.nix self;
        };
      }
    );
}
