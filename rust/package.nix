{
  lib,
  rustPlatform,
}:
let
  inherit ((fromTOML (builtins.readFile ./Cargo.toml)).package) version name;
in
rustPlatform.buildRustPackage {
  pname = name;
  inherit version;
  src = lib.cleanSource ./.;
  cargoLock.lockFile = ./Cargo.lock;
}
