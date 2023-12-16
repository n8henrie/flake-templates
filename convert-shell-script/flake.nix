{
  description = "Nixify an existing shell script. Thanksto https://ertt.ca/nix/shell-scripts/";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-23.11";

  outputs = {
    self,
    nixpkgs,
  }: let
    inherit (nixpkgs) lib;
    systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];
    name = "my-script";
    systemClosure = attrs:
      builtins.foldl' (acc: system:
        lib.recursiveUpdate acc (attrs system)) {}
      systems;
  in
    systemClosure (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [self.overlays.default];
        };
        buildInputs = with pkgs; [cowsay];
        script =
          (pkgs.writeScriptBin name (builtins.readFile ./simple-script.sh))
          .overrideAttrs (old: {
            buildCommand = ''
              ${old.buildCommand}
              patchShebangs $out;
            '';
          });
      in {
        overlays = {
          default = self.overlays.${name};
          ${name} = _: prev: {
            # inherit doesn't work with dynamic attributes
            ${name} = (self.packages.${prev.system}).${name};
          };
        };

        packages.${system} = {
          default = self.outputs.packages.${system}.script;
          script = pkgs.symlinkJoin {
            inherit name;
            paths = [script] ++ buildInputs;
            nativeBuildInputs = [pkgs.makeBinaryWrapper];
            postBuild = "wrapProgram $out/bin/${name} --set PATH $out/bin";
          };
        };

        apps.${system}.default = {
          type = "app";
          program = "${self.packages.${system}.script}/bin/${name}";
        };

        devShells.${system}.default = pkgs.mkShell {
          inherit buildInputs;
        };
      }
    );
}
