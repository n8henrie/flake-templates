{
  description = "Flake for https://github.com/n8henrie/foo";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
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
        pname = (fromTOML (builtins.readFile ./pyproject.toml)).project.name;
        pyPkgs = pkgs.python313.pkgs;
      in
      {
        packages = {
          default = pyPkgs.python.withPackages (ps: [
            (ps.callPackage ./package.nix { })
          ]);
          ${pname} = pyPkgs.callPackage ./. { };
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
