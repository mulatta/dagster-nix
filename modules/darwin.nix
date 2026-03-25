{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.dagster;
  ws = import ./workspace.nix { inherit cfg lib pkgs; };

  commonEnv = {
    DAGSTER_HOME = cfg.workspaceDir;
  };
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable {
    services.dagster.webserver.package = lib.mkDefault cfg.package;
    services.dagster.codeServers = lib.mapAttrs (_name: _cs: {
      package = lib.mkDefault cfg.package;
    }) cfg.codeServers;

    inherit (ws) assertions;

    launchd.daemons =
      # Webserver
      lib.optionalAttrs cfg.webserver.enable {
        dagster-webserver = {
          serviceConfig = {
            Label = "com.dagster.webserver";
            ProgramArguments = [
              (lib.getExe cfg.webserver.package)
              "--host"
              cfg.webserver.host
              "--port"
              (toString cfg.webserver.port)
            ]
            ++ ws.workspaceArgs
            ++ cfg.webserver.extraArgs;
            EnvironmentVariables = commonEnv;
            WorkingDirectory = cfg.workspaceDir;
            RunAtLoad = true;
            KeepAlive = true;
            StandardOutPath = "/var/log/dagster-webserver.log";
            StandardErrorPath = "/var/log/dagster-webserver.log";
          };
        };
      }
      # Daemon
      // lib.optionalAttrs cfg.daemon.enable {
        dagster-daemon = {
          serviceConfig = {
            Label = "com.dagster.daemon";
            ProgramArguments = [
              "${lib.getBin cfg.package}/bin/dagster-daemon"
              "run"
            ]
            ++ ws.workspaceArgs
            ++ cfg.daemon.extraArgs;
            EnvironmentVariables = commonEnv;
            WorkingDirectory = cfg.workspaceDir;
            RunAtLoad = true;
            KeepAlive = true;
            StandardOutPath = "/var/log/dagster-daemon.log";
            StandardErrorPath = "/var/log/dagster-daemon.log";
          };
        };
      }
      # Code servers
      // lib.mapAttrs' (
        name: cs:
        lib.nameValuePair "dagster-code-${name}" {
          serviceConfig = {
            Label = "com.dagster.code.${name}";
            ProgramArguments = ws.codeServerArgs name cs;
            EnvironmentVariables = commonEnv;
            WorkingDirectory = cfg.workspaceDir;
            RunAtLoad = true;
            KeepAlive = true;
            StandardOutPath = "/var/log/dagster-code-${name}.log";
            StandardErrorPath = "/var/log/dagster-code-${name}.log";
          };
        }
      ) cfg.codeServers;
  };
}
