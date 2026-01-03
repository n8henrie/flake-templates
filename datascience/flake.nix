{
  description = "Basic setup for data sciencey stuff";
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
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            (pkgs.python3.withPackages (
              ps: with ps; [
                altair
                marimo
                polars
                ruff
                scikit-learn
                sqlalchemy
              ]
            ))
          ]
          ++ (with pkgs; [
            nodejs
            ty
          ]);
        };
      }
    );
}
