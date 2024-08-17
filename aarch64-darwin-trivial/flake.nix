{
  description = "Very basic template for darwin";

  outputs =
    { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      name = "say-hello";
    in
    {
      packages.${system}.default = pkgs.writeShellScriptBin name "echo hello there";
      apps.${system}.default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/${name}";
      };
      devShells.${system}.default = pkgs.mkShellNoCC {
        nativeBuildInputs = [ ];
        buildInputs = [ ];
      };
    };
}
