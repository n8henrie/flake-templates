{
  pname,
  lib,
  buildPythonPackage,
  setuptools-scm,
}:
buildPythonPackage {
  inherit pname;
  version = builtins.elemAt (lib.splitString "\"" (
    lib.findSingle (val: builtins.match "^__version__ = \".*\"$" val != null) (abort "none")
      (abort "multiple")
      (lib.splitString "\n" (builtins.readFile ./src/${pname}/__init__.py))
  )) 1;

  src = lib.cleanSource ./.;
  pyproject = true;
  build-system = [ setuptools-scm ];
  dependencies = [ ];
}
