{
  description = "A very basic flake";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-23.11";

  outputs = {
    self,
    nixpkgs,
  }: let
    inherit (nixpkgs) lib;
    systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];
    name = "foo";
  in
    builtins.foldl' (acc: system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
      };
    in
      lib.recursiveUpdate acc {
        overlays = {
          default = self.overlays.${name};
          ${name} = _: prev: {
            # inherit doesn't work with dynamic attributes
            ${name} = (self.packages.${prev.system}).${name};
          };
        };
        packages.${system} = {
          default = self.packages.${system}.foo;
          foo = pkgs.stdenv.mkDerivation {
            inherit name;
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
