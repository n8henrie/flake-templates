{
  description = "A very basic flake";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-23.11";

  outputs = {
    self,
    nixpkgs,
  }: let
    name = "";
    systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];
    eachSystem = with nixpkgs.lib;
      f:
        foldAttrs mergeAttrs {}
        (map (s: mapAttrs (_: v: {${s} = v;}) (f s)) systems);
  in
    {
      overlays = {
        default = self.overlays.${name};
        ${name} = _: prev: {
          # inherit doesn't work with dynamic attributes
          ${name} = self.packages.${prev.system}.${name};
        };
      };
    }
    // (eachSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [self.overlays.default];
        };
      in {
        packages.${system} = {
          default = self.packages.${system}.${name};
          ${name} = pkgs.hello;
        };

        apps.${system}.default = {
          type = "app";
          program = "${self.packages.${system}.${name}}/bin/${name}";
        };

        devShells.${system}.default =
          pkgs.mkShell {
          };
      }
    ));
}
