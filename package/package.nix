{
  name,
  lib,
  stdenv,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = name;
  version = "0.0.1";
  src = lib.cleanSource ./.;
  nativeBuildInputs = [ ];
  buildInputs = [ ];
})
