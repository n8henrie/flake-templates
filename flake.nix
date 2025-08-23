{
  description = "n8henrie's flake templates";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    aarch64-darwin-trivial.url = ./aarch64-darwin-trivial;
    convert-shell-script.url = ./convert-shell-script;
    cpp.url = ./cpp;
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
    eachSystem (system: {
      checks = lib.pipe self.inputs [
        (lib.filterAttrs (n: v: n != "nixpkgs" && builtins.hasAttr "checks" v))
        (lib.concatMapAttrs (
          fname: fval:
          (lib.mapAttrs' (cname: cval: {
            name = "${fname}-${cname}";
            value = cval;
          }) fval.checks.${system})
        ))
      ];
    })
    // {
      templates = builtins.mapAttrs (_: v: {
        path = v;
        inherit (import "${v}/flake.nix") description;
      }) self.inputs;
    };
}
