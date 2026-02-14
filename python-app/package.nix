{
  pname,
  lib,
  writers,
  buildPythonApplication,
  pythonImportsCheckHook,
  setuptools-scm,
  pyPkgs,
}:
buildPythonApplication (finalAttrs: {
  inherit pname;
  preBuild =
    let
      toml =
        let
          cleanName = builtins.replaceStrings [ "-" ] [ "_" ] finalAttrs.pname;
        in
        writers.writeTOML "pyproject.toml" {
          build-system = {
            requires = [ "setuptools" ];
            build-backend = "setuptools.build_meta";
          };
          project = {
            inherit (finalAttrs) version;
            name = pname;
          };
          project.scripts.${pname} = "${cleanName}:main";
          tool.setuptools.py-modules = [ cleanName ];
        };
    in
    "cp ${toml} pyproject.toml";
  version = "0.0.1";
  src = lib.cleanSource ./.;
  pyproject = true;
  build-system = [ setuptools-scm ];
  dependencies = with pyPkgs; [ ];
  checkInputs = [ pythonImportsCheckHook ];
  meta.mainProgram = pname;
})
