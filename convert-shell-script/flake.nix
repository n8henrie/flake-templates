{
  description = "Nixify an existing shell script. Thanksto https://ertt.ca/nix/shell-scripts/";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs =
    { self, nixpkgs }:
    let
      name = "my-script";
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
        buildInputs = with pkgs; [ cowsay ];
        script = (pkgs.writeScriptBin name (builtins.readFile ./simple-script.sh)).overrideAttrs (old: {
          buildCommand = ''
            ${old.buildCommand}
            patchShebangs $out;

            # substituteInPlace $target --replace-fail "foo" "bar"
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
    );
}
