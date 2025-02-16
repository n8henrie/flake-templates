{
  description = "Flake for https://github.com/n8henrie/foo";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";

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
        pyPkgs = pkgs.python313.pkgs;
      in
      {
        packages.default = pyPkgs.playwright.overrideAttrs {
          postInstall =
            let
              inherit (pkgs.playwright-driver) browsers;
            in
            ''
              wrapProgram $out/bin/playwright \
                --set PLAYWRIGHT_BROWSERS_PATH "${browsers}"
            '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python39
            python310
            python311
            python312
            (pyPkgs.python.withPackages (
              ps:
              (with ps; [
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
