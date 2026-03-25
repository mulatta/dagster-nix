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

  commonServiceConfig = {
    User = "dagster";
    Group = "dagster";
    WorkingDirectory = cfg.workspaceDir;
    Restart = "on-failure";
    RestartSec = 5;

    # Hardening
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    ReadWritePaths = [ cfg.workspaceDir ];
    PrivateTmp = true;
  }
  // lib.optionalAttrs (cfg.environmentFile != null) {
    EnvironmentFile = cfg.environmentFile;
  };

  commonEnvironment = {
    DAGSTER_HOME = cfg.workspaceDir;
  }
  // lib.optionalAttrs dy.hasPg {
    DAGSTER_PG_URL = dy.postgresUrl;
  };

  codeServerNames = lib.mapAttrsToList (name: _: "dagster-code-${name}.service") cfg.codeServers;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable {
    assertions = ws.assertions ++ dy.assertions;

    users.users.dagster = {
      isSystemUser = true;
      group = "dagster";
      home = cfg.workspaceDir;
      createHome = true;
    };
    users.groups.dagster = { };

    # Symlink dagster.yaml into DAGSTER_HOME
    systemd.tmpfiles.rules = [
      "L+ ${cfg.workspaceDir}/dagster.yaml - - - - ${dy.configFile}"
    ];

    systemd.services =
      # Webserver
      lib.optionalAttrs cfg.webserver.enable {
        dagster-webserver = {
          description = "Dagster Webserver";
          after = [ "network.target" ] ++ codeServerNames;
          wantedBy = [ "multi-user.target" ];
          environment = commonEnvironment;

          serviceConfig = commonServiceConfig // {
            ExecStart = lib.concatStringsSep " " (
              [
                (lib.getExe cfg.webserver.package)
                "--host"
                cfg.webserver.host
                "--port"
                (toString cfg.webserver.port)
              ]
              ++ ws.workspaceArgs
              ++ cfg.webserver.extraArgs
            );
          };
        };
      }
      # Daemon
      // lib.optionalAttrs cfg.daemon.enable {
        dagster-daemon = {
          description = "Dagster Daemon";
          after = [ "network.target" ] ++ codeServerNames;
          wantedBy = [ "multi-user.target" ];
          environment = commonEnvironment;

          serviceConfig = commonServiceConfig // {
            ExecStart = lib.concatStringsSep " " (
              [
                "${lib.getBin cfg.package}/bin/dagster-daemon"
                "run"
              ]
              ++ ws.workspaceArgs
              ++ cfg.daemon.extraArgs
            );
          };
        };
      }
      # Code servers
      // lib.mapAttrs' (
        name: cs:
        lib.nameValuePair "dagster-code-${name}" {
          description = "Dagster Code Server (${name})";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          environment = commonEnvironment;

          serviceConfig = commonServiceConfig // {
            ExecStart = lib.concatStringsSep " " (ws.codeServerArgs name cs);
          };
        }
      ) cfg.codeServers;
  };
}
