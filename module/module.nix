flake:
{
  pkgs,
  config,
  lib,
  options,
  ...
}:
let
  service_name = "my_service";
  cfg = config.services.${service_name};
in
{
  options.services.${service_name} =
    let
      inherit (lib) mkEnableOption mkOption types;
    in
    {
      enable = mkEnableOption service_name;
      user = mkOption {
        type = types.str;
        default = config.users.users.n8henrie.name;
      };
      schedule = mkOption {
        type =
          with types;
          submodule {
            options = {
              Hour = mkOption {
                type = ints.between 0 23;
                description = "Hour of day to run";
                default = 1;
              };
              Minute = mkOption {
                type = ints.between 0 59;
                description = "Minute of the hour to run";
                default = 5;
              };
            };
          };
        default = { };
      };
    }
    // (
      with ((options.launchd.agents.type.getSubOptions [ ]).serviceConfig.type.getSubOptions [ ]);
      let
        logbase = "${config.users.users.n8henrie.home}/git/${service_name}";
      in
      {
        stdout = StandardOutPath // {
          default = "${logbase}/stdout.log";
        };
        stderr = StandardErrorPath // {
          default = "${logbase}/stderr.log";
        };
      }
    );

  config =
    let
      inherit (lib) mkIf mkMerge optionalAttrs;
      script = lib.getExe (
        pkgs.writeShellApplication {
          name = service_name;
          runtimeInputs = with pkgs; [ ];
          text = "echo 'this is my service'";
        }
      );
    in
    mkIf cfg.enable (mkMerge [
      (optionalAttrs (options ? systemd) {
        systemd.services.${service_name} =
          let
            after = [ "network-online.target" ];
          in
          {
            inherit after script;
            description = service_name;
            requires = after;
            unitConfig.ConditionPathExists = cfg.path;
            serviceConfig = {
              User = cfg.user;
              Restart = "on-failure";
            };
            wantedBy = [ "multi-user.target" ];
          };
        systemd.timers.${service_name} = {
          timerConfig = {
            OnBootSec = "30min";
            OnCalendar =
              let
                twoDigitString = lib.fixedWidthNumber 2;
              in
              "*-*-* ${twoDigitString cfg.schedule.Hour}:${twoDigitString cfg.schedule.Minute}";
          };
          wantedBy = [ "timers.target" ];
        };
      })

      (optionalAttrs (options ? launchd) {
        launchd.user.agents.${service_name} = {
          serviceConfig = {
            Label = "com.n8henrie.${service_name}";
            ProgramArguments = [ "${script}/bin/${service_name}" ];
            StartCalendarInterval = [ { inherit (cfg.schedule) Hour Minute; } ];
            LowPriorityIO = true;
            Nice = 20;
            StandardOutPath = cfg.stdout;
            StandardErrorPath = cfg.stderr;
            TimeOut = 600;
          };
        };
      })
    ]);
}
