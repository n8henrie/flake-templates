{
  description = "n8henrie's flake templates";

  outputs = {...}: {
    templates = {
      trivial = {
        path = ./trivial;
        description = "Trivial with multi-system outputs";
      };
      cpp = {
        path = ./cpp;
        description = "Basic example compiling a cpp program";
      };
    };
  };
}
