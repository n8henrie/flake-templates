{
  pname,
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  inherit pname;
  version =
    if builtins.pathExists ./Cargo.toml then
      (builtins.fromTOML (builtins.readFile ./Cargo.toml)).package.version
    else
      "placeholder";
  src = lib.cleanSource ./.;
  cargoLock.lockFile = ./Cargo.lock;
}
