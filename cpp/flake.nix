{
  description = "A very basic flake";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "x86_64-darwin"
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      name = "foo";
    in
    builtins.foldl' (
      acc: system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      lib.recursiveUpdate acc {
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
