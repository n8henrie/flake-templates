{
  description = "Basic setup for data sciencey stuff with jupyter / python";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs =
    { self, nixpkgs }:
    let
      name = "jupyter-example";
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
    {
      overlays = {
        default = self.overlays.${name};
        ${name} = _: prev: {
          # inherit doesn't work with dynamic attributes
          ${name} = self.packages.${prev.system}.${name};
        };
      };
    }
    // (eachSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      in
      {
        packages =
          let
            jupyter-black =
              let
                pname = "jupyter-black";
                version = "0.3.4";
              in
              pkgs.python311Packages.buildPythonPackage {
                inherit pname version;
                format = "pyproject";
                propagatedBuildInputs = with pkgs.python311Packages; [
                  black
                  ipython
                  tokenize-rt
                  setuptools-scm
                ];
                src = pkgs.fetchPypi {
                  inherit pname version;
                  hash = "sha256-KjjzPUwyHrdo9CYQNjWsm4C0DJ5CqgYHKnKePK3cpMM=";
                };
              };
          in
          {
            default = pkgs.python311.withPackages (
              ps: with ps; [
                hvplot
                jupyter-black
                jupyterlab
                matplotlib
                polars
                pyarrow
                scikitlearn
              ]
            );
          };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/jupyter-lab";
        };
      }
    ));
}
