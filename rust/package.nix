{
  lib,
  rustPlatform,
}:
# let
#   inherit ((fromTOML (builtins.readFile ./Cargo.toml)).package) version name;
# in
rustPlatform.buildRustPackage (finalAttrs: {
  # pname = name;
  # inherit version
  pname =
    if builtins.pathExists ./Cargo.toml then
      (fromTOML (builtins.readFile ./Cargo.toml)).package.name
    else
      "placeholder";
  version =
    if builtins.pathExists ./Cargo.toml then
      (fromTOML (builtins.readFile ./Cargo.toml)).package.version
    else
      "placeholder";
  src = lib.cleanSource ./.;
  cargoLock.lockFile = ./Cargo.lock;
})
