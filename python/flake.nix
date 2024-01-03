{
  description = "Flake for https://github.com/n8henrie/foo";

  inputs = {
    # For python3.7
    nixpkgs-old.url = "github:nixos/nixpkgs/release-22.11";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-old,
  }: let
    inherit (nixpkgs) lib;
    systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];
    systemClosure = attrs:
      builtins.foldl'
      (acc: system:
        lib.recursiveUpdate acc (attrs system))
      {}
      systems;
  in
    systemClosure (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (_: _: {
              inherit (nixpkgs-old.legacyPackages.${system}) python37;
            })
          ];
        };
        pname = "foo";
        propagatedBuildInputs = with pkgs.python311Packages; [];
        ${pname} = {
          lib,
          python311,
        }:
          python311.pkgs.buildPythonPackage {
            inherit pname;
            version =
              builtins.elemAt
              (lib.splitString "\""
                (lib.findSingle
                  (val: builtins.match "^__version__ = \".*\"$" val != null)
                  (abort "none")
                  (abort "multiple")
                  (lib.splitString "\n"
                    (builtins.readFile ./src/${pname}/__init__.py))))
              1;

            src = lib.cleanSource ./.;
            pyproject = true;
            nativeBuildInputs = with pkgs.python311Packages; [
              setuptools-scm
            ];
            inherit propagatedBuildInputs;
          };
      in {
        packages.${system} = {
          ${pname} = pkgs.callPackage pname {};
          default = pkgs.python311.withPackages (_: [self.packages.${system}.${pname}]);
        };

        devShells.${system}.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python37
            python38
            python39
            python310
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
