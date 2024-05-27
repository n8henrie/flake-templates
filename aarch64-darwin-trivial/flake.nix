{
  description = "Very basic template for darwin";

  outputs =
    { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
      name = "say-hello";
    in
    {
      overlays = {
        default = self.overlays.${name};
        ${name} = _: prev: {
          # inherit doesn't work with dynamic attributes
          ${name} = self.packages.${prev.system}.${name};
        };
      };
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
