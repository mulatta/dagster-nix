{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.dagster;
in
{
  options.services.dagster = {
    enable = lib.mkEnableOption "Dagster webserver";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.python313Packages.dagster-webserver;
      defaultText = lib.literalExpression "pkgs.python313Packages.dagster-webserver";
      description = "The dagster-webserver package to use.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host to bind the webserver to.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port for the dagster webserver.";
    };

    workspaceDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/dagster";
      description = "Dagster home directory for storage and workspace config.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra arguments passed to dagster-webserver.";
    };
  };

  config = lib.mkIf cfg.enable {
    launchd.daemons.dagster-webserver = {
      serviceConfig = {
        Label = "com.dagster.webserver";
        ProgramArguments = [
          (lib.getExe cfg.package)
          "--host"
          cfg.host
          "--port"
          (toString cfg.port)
        ]
        ++ cfg.extraArgs;
        EnvironmentVariables.DAGSTER_HOME = cfg.workspaceDir;
        WorkingDirectory = cfg.workspaceDir;
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/var/log/dagster-webserver.log";
        StandardErrorPath = "/var/log/dagster-webserver.log";
      };
    };
  };
}
