{
  description = "Nixify an existing shell script. Thanksto https://ertt.ca/nix/shell-scripts/";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs =
    { self, nixpkgs }:
    let
      name = "my-script";
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      eachSystem =
        with nixpkgs.lib;
        f: foldAttrs mergeAttrs { } (map (s: mapAttrs (_: v: { ${s} = v; }) (f s)) systems);
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
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
        buildInputs = with pkgs; [ cowsay ];
        script = (pkgs.writeScriptBin name (builtins.readFile ./simple-script.sh)).overrideAttrs (old: {
          buildCommand = ''
            ${old.buildCommand}
            patchShebangs $out;
          '';
        });
      in
      {
        packages = {
          default = self.outputs.packages.${system}.script;
          script = pkgs.symlinkJoin {
            inherit name;
            paths = [ script ] ++ buildInputs;
            nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
            postBuild = "wrapProgram $out/bin/${name} --set PATH $out/bin";
          };
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.script}/bin/${name}";
        };

        devShells.default = pkgs.mkShell { inherit buildInputs; };
      }
    ));
}
