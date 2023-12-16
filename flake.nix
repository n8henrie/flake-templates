{
  description = "n8henrie's flake templates";

  outputs = {...}: {
    templates = {
      aarch64-darwin-trivial = {
        path = ./aarch64-darwin-trivial;
        description = "Very basic setup for aarch64-darwin";
      };
      convert-shell-script = {
        path = ./convert-shell-script;
        description = "Nixify an existing shell script";
      }:
      cpp = {
        path = ./cpp;
        description = "Basic example compiling a cpp program";
      };
      rust = {
        path = ./rust;
        description = "Basic rust template";
      };
      selenium-rs = {
        path = ./selenium-rs;
        description = "Example using thirtyfour for selenium in rust";
      };
      trivial = {
        path = ./trivial;
        description = "Trivial with multi-system outputs";
      };
    };
  };
}
