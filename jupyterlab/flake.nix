{
  description = "Basic setup for data sciencey stuff with jupyter / python";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-23.11";

  outputs = {
    self,
    nixpkgs,
  }: let
    name = "jupyter-example";
    inherit (nixpkgs) lib;
    systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];
    systemClosure = attrs:
      builtins.foldl' (acc: system:
        lib.recursiveUpdate acc (attrs system)) {}
      systems;
  in
    systemClosure (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [self.overlays.default];
        };
      in {
        overlays = {
          default = self.overlays.${name};
          ${name} = _: prev: {
            # inherit doesn't work with dynamic attributes
            ${name} = self.packages.${prev.system}.${name};
          };
        };
        packages.${system} = let
          jupyter-black = let
            pname = "jupyter-black";
            version = "0.3.4";
          in
            pkgs.python311Packages.buildPythonPackage {
              inherit pname version;
              format = "pyproject";
              propagatedBuildInputs = with pkgs.python311Packages; [
                black
                setuptools-scm
              ];
              src = pkgs.fetchPypi {
                inherit pname version;
                hash = "sha256-KjjzPUwyHrdo9CYQNjWsm4C0DJ5CqgYHKnKePK3cpMM=";
              };
            };
        in {
          default = pkgs.python311.withPackages (ps:
            with ps; [
              jupyter-black
              jupyterlab
              matplotlib
              pandas
              polars
              pyarrow
              sklearn
            ]);
        };

        apps.${system}.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/jupyter-lab";
        };
      }
    );
}
