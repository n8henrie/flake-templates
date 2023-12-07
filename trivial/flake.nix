{
  description = "A very basic flake";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-23.11";

  outputs = {
    self,
    nixpkgs,
  }: let
    inherit (nixpkgs) lib;
    systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];
    systemClosure = attrs:
      builtins.foldl' (acc: system:
        lib.recursiveUpdate acc (attrs system)) {}
      systems;
  in
    systemClosure (
      system: let
        pkgs = import nixpkgs {inherit system;};
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

        devShells.${system}.default =
          pkgs.mkShell {
          };
      }
    );
}
