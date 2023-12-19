{
  description = "n8henrie's flake templates";

  outputs = {nixpkgs, ...}: let
    inherit (nixpkgs) lib;
    getTemplate = name: {
      path = ./${name};
      inherit (import "./${name}/flake.nix") description;
    };
    templateBuilder = names: lib.genAttrs names getTemplate;
  in {
    templates = templateBuilder [
      "aarch64-darwin-trivial"
      "convert-shell-script"
      "cpp"
      "jupyterlab"
      "rust"
      "selenium-rs"
      "trivial"
    ];
  };
}
