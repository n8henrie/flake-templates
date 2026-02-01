{
  description = "Nixify an existing shell script. Provide binary wrapper for macOS permissions.";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      name = "my-script";
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
        buildInputs = [ ];
      in
      {
        packages = {
          default = self.outputs.packages.${system}.${name};
          ${name} = pkgs.callPackage ./. { inherit buildInputs name; };
        };

        apps.default = {
          type = "app";
          program = pkgs.lib.getExe' self.packages.${system}.default name;
        };

        devShells.default = pkgs.mkShell { inherit buildInputs; };
      }
    );
}
