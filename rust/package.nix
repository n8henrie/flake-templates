{
  lib,
  rustPlatform,
}:
# let
# inherit ((lib.importTOML ./Cargo.toml).package) name version;
# in
rustPlatform.buildRustPackage (finalAttrs: {
  # pname = name;
  # inherit version
  pname =
    if builtins.pathExists ./Cargo.toml then
      (lib.importTOML ./Cargo.toml).package.name
    else
      "placeholder";
  version =
    if builtins.pathExists ./Cargo.toml then
      (lib.importTOML ./Cargo.toml).package.version
    else
      "placeholder";
  src = lib.cleanSource ./.;
  cargoLock.lockFile = ./Cargo.lock;
})
