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
    eachSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pyPkgs = pkgs.python313Packages;

      in
      {
        packages =
          let
            jupyter-black =
              let
                pname = "jupyter-black";
                version = "0.3.4";
              in
              pyPkgs.buildPythonPackage {
                inherit pname version;
                format = "pyproject";
                propagatedBuildInputs = with pyPkgs; [
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
            default = self.outputs.packages.${system}.${name};
            ${name} = pkgs.symlinkJoin {
              name = "data";
              paths = with pkgs; [
                nodejs
                (pyPkgs.python.withPackages (
                  ps: with ps; [
                    altair
                    (hvplot.overridePythonAttrs {
                      # 20250215 dask failing to build, only needed in checkPhase
                      doCheck = false;
                    })
                    jupyter-black
                    jupyterlab
                    marimo
                    matplotlib
                    nbconvert
                    polars
                    pyarrow
                    scikitlearn
                    statsmodels
                    xlsx2csv
                  ]
                ))
              ];
              buildInputs = [ pkgs.makeBinaryWrapper ];
              postBuild = "wrapProgram $out/bin/marimo --prefix PATH : $out/bin";
            };
          };

        apps = {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/jupyter-lab";
          };
          marimo = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/marimo";
          };
        };
      }
    );
}
