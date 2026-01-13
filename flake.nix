{
  description = "n8henrie's flake templates";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    aarch64-darwin-trivial.url = ./aarch64-darwin-trivial;
    convert-shell-script.url = ./convert-shell-script;
    cpp.url = ./cpp;
    datascience.url = ./datascience;
    jupyterlab.url = ./jupyterlab;
    playwright.url = ./playwright;
    python.url = ./python;
    rust-oxalica.url = ./rust-oxalica;
    rust.url = ./rust;
    selenium-rs.url = ./selenium-rs;
    trivial.url = ./trivial;
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "x86_64-darwin"
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      eachSystem =
        with lib;
        f: foldAttrs mergeAttrs { } (map (s: mapAttrs (_: v: { ${s} = v; }) (f s)) systems);
    in
    eachSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        checks =
          lib.pipe self.inputs [
            (lib.filterAttrs (n: v: n != "nixpkgs" && builtins.hasAttr "checks" v))
            (lib.concatMapAttrs (
              fname: fval:
              (lib.mapAttrs' (cname: cval: {
                name = "${fname}-${cname}";
                value = cval;
              }) fval.checks.${system})
            ))
          ]
          // {
            lint =
              pkgs.runCommandLocal "lint"
                {
                  src = pkgs.lib.cleanSource ./.;
                  nativeBuildInputs = with pkgs; [
                    deadnix
                    nixfmt
                    statix
                  ];
                }
                ''
                  deadnix --fail .
                  statix check
                  find . -name '*.nix' -exec nixfmt --check {} +
                  touch $out
                '';
          };
      }
    )
    // {
      templates = builtins.mapAttrs (_: v: {
        path = v;
        inherit (import "${v}/flake.nix") description;
      }) self.inputs;
    };
}
