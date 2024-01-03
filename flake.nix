{
  description = "n8henrie's flake templates";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-23.11";
  outputs = {nixpkgs, ...}: let
    inherit (nixpkgs) lib;
    getTemplate = name: {
      path = ./${name};
      inherit (import ./${name}/flake.nix) description;
    };
    templateBuilder = names: lib.genAttrs names getTemplate;
  in {
    templates = templateBuilder [
      "aarch64-darwin-trivial"
      "convert-shell-script"
      "cpp"
      "jupyterlab"
      "python"
      "rust"
      "selenium-rs"
      "trivial"
    ];
  };
}
