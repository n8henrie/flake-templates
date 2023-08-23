{
  description = "A very basic flake";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-23.05";

  outputs = {
    self,
    nixpkgs,
  }: let
    inherit (nixpkgs) lib;
    systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];
    systemGen = attrs:
      builtins.foldl' (acc: system:
        lib.recursiveUpdate acc (attrs {
          inherit system;
          pkgs = import nixpkgs {inherit system;};
        })) {}
      systems;
  in
    systemGen (
      {
        pkgs,
        system,
      }: let
        pname = "foo";
      in {
        packages.${system} = {
          default = self.packages.${system}.${pname};
          ${pname} = pkgs.hello;
        };

        apps.${system}.default = {
          type = "app";
          program = "${self.packages.${system}.${pname}}/bin/hello";
        };
      }
    );
}
