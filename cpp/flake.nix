{
  description = "A very basic flake";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      name = "foo";
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
        packages.${system} = {
          default = self.packages.${system}.foo;
          foo = pkgs.stdenv.mkDerivation {
            inherit name;
            src = ./foo.cpp;
            dontUnpack = true;
            buildInputs = [ pkgs.gcc ];
            buildPhase = ''
              g++ -o foo $src
            '';
            installPhase = ''
              mkdir -p "$out/bin"
              cp ./foo "$out/bin/"
            '';
          };
        };

        apps.${system}.default = {
          type = "app";
          program = "${self.packages.${system}.foo}/bin/foo";
        };
      }
    ) { } systems;
}
