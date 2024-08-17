{
  description = "Flake for https://github.com/n8henrie/foo";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs =
    { self, nixpkgs }:
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
        pname = "foo";
        pypkgs = pkgs.python311Packages;
        propagatedBuildInputs = with pypkgs; [ ];
      in
      {
        packages = {
          default = pkgs.python311.withPackages (_: [
            (pkgs.callPackage self.packages.${system}.${pname} { })
          ]);
          ${pname} =
            { lib, python311 }:
            python311.pkgs.buildPythonPackage {
              inherit pname;
              version = builtins.elemAt (lib.splitString "\"" (
                lib.findSingle (val: builtins.match "^__version__ = \".*\"$" val != null) (abort "none")
                  (abort "multiple")
                  (lib.splitString "\n" (builtins.readFile ./src/${pname}/__init__.py))
              )) 1;

              src = lib.cleanSource ./.;
              pyproject = true;
              nativeBuildInputs = with pypkgs; [ setuptools-scm ];
              inherit propagatedBuildInputs;
            };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python38
            python39
            python310
            python312
            (python311.withPackages (
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
