{
  description = "Reproducible playwright scripts via nix";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";

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
        pyPkgs = pkgs.python313.pkgs;
      in
      {
        packages = {
          default = self.outputs.packages.${system}.python-with-playwright;
          python-with-playwright = pyPkgs.python.buildEnv.override (old: {
            extraLibs = with pyPkgs; [
              playwright
              pytest
            ];
            makeWrapperArgs =
              let
                inherit (pkgs.playwright-driver) browsers;
              in
              old.makeWrapperArgs or [ ] ++ [ "--set-default PLAYWRIGHT_BROWSERS_PATH ${browsers}" ];
          });
        };

        devShells.default = self.outputs.packages.${system}.python-with-playwright.env;
      }
    );
}
