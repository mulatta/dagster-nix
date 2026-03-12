{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.dagster;
  ws = import ./workspace.nix { inherit cfg lib pkgs; };
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable {
    inherit (ws) assertions;

    launchd.daemons = {
      dagster-webserver = {
        serviceConfig = {
          Label = "com.dagster.webserver";
          ProgramArguments = [
            (lib.getExe cfg.package)
            "--host"
            cfg.host
            "--port"
            (toString cfg.port)
          ]
          ++ ws.workspaceArgs
          ++ cfg.extraArgs;
          EnvironmentVariables.DAGSTER_HOME = cfg.workspaceDir;
          WorkingDirectory = cfg.workspaceDir;
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/var/log/dagster-webserver.log";
          StandardErrorPath = "/var/log/dagster-webserver.log";
        };
      };
    }
    // lib.mapAttrs' (
      name: cs:
      lib.nameValuePair "dagster-code-${name}" {
        serviceConfig = {
          Label = "com.dagster.code.${name}";
          ProgramArguments = ws.codeServerArgs name cs;
          EnvironmentVariables.DAGSTER_HOME = cfg.workspaceDir;
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
