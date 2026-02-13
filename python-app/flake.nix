{
  description = "";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs, ... }:
    let
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
        name = "";
        pyPkgs = pkgs.python314.pkgs;
      in
      {
        packages = {
          default = self.outputs.packages.${system}.${name};
          ${name} = pyPkgs.callPackage ./package.nix {
            inherit pyPkgs;
            pname = name;
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python310
            python311
            python312
            python313
            (pyPkgs.python.withPackages (
              ps:
              propagatedBuildInputs
              ++ (with ps; [
                mypy
                pytest
                tox
              ])
            ))
          ];
        };
      }
    );
}
