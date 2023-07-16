{
  description = "A very basic flake";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-23.05";

  outputs = {
    self,
    nixpkgs,
  }: let
    inherit (nixpkgs) lib;
    systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];
  in
    builtins.foldl' (acc: system: let
      pkgs = import nixpkgs {inherit system;};
    in
      lib.recursiveUpdate acc {
        packages.${system} = {
          default = self.packages.${system}.foo;
          foo = pkgs.stdenv.mkDerivation {
            name = "foo";
            src = ./foo.cpp;
            dontUnpack = true;
            buildInputs = [pkgs.gcc];
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
      }) {}
    systems;
}
