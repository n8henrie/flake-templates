{
  description = "A very basic flake";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-23.05";

  outputs = {
    self,
    nixpkgs,
  }: {
    packages =
      nixpkgs.lib.genAttrs
      ["aarch64-darwin" "x86_64-linux" "aarch64-linux"]
      (system: let
        pkgs = import nixpkgs {inherit system;};
      in {
        package = pkgs.hello;
        default = self.packages.${system}.package;
      });
  };
}
