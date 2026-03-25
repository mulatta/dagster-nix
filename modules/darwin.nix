{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.dagster;
  ws = import ./workspace.nix { inherit cfg lib pkgs; };
  dy = import ./dagster-yaml.nix { inherit cfg lib pkgs; };

  commonEnv = {
    DAGSTER_HOME = cfg.workspaceDir;
  }
  // lib.optionalAttrs dy.hasPg {
    DAGSTER_PG_URL = dy.postgresUrl;
  };
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable {
    services.dagster.webserver.package = lib.mkDefault cfg.package;

    assertions = ws.assertions ++ dy.assertions;

    warnings = lib.optionals (dy.hasPg && cfg.settings.storage.postgres.createLocally) [
      "services.dagster: nix-darwin does not support ensureDatabases/ensureUsers. You must manually create the '${cfg.settings.storage.postgres.database}' database and '${cfg.settings.storage.postgres.user}' user."
    ];

    services.postgresql = lib.mkIf (dy.hasPg && cfg.settings.storage.postgres.createLocally) {
      enable = true;
    };

    # Ensure DAGSTER_HOME exists and symlink dagster.yaml
    system.activationScripts.postActivation.text = ''
      mkdir -p ${cfg.workspaceDir}
      ln -sfn ${dy.configFile} ${cfg.workspaceDir}/dagster.yaml
    '';

    launchd.daemons =
      # Webserver
      lib.optionalAttrs cfg.webserver.enable {
        dagster-webserver = {
          serviceConfig = {
            Label = "com.dagster.webserver";
            ProgramArguments = [
              (lib.getExe' cfg.webserver.package "dagster-webserver")
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
