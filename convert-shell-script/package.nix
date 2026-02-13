{
  lib,
  name,
  buildInputs,
  makeBinaryWrapper,
  runtimeShell,
  writeShellApplication,
}:
(writeShellApplication {
  inherit name;
  text = builtins.readFile ./${name}.sh;
  runtimeInputs = buildInputs;
  derivationArgs.nativeBuildInputs = [ makeBinaryWrapper ];
}).overrideAttrs
  (old: {
    buildCommand =
      old.buildCommand
      + ''
        wrapProgram $out/bin/${name} \
            --set PATH ${lib.makeBinPath [ runtimeShell ]}
      '';
  })
