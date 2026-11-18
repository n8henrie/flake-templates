{
  description = "Flake for https://github.com/n8henrie/foo";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
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
        inherit ((nixpkgs.lib.importTOML ./pyproject.toml).project) name;
        pkgs = nixpkgs.legacyPackages.${system};
        pyPkgs = pkgs.python313.pkgs;
      in
      {
        packages = {
          default = pyPkgs.python.withPackages (ps: [
            (ps.callPackage ./package.nix { })
          ]);
          ${name} = pyPkgs.callPackage ./package.nix { };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python39
            python310
            python311
            python312
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
