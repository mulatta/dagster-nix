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

    users.users.dagster = {
      isSystemUser = true;
      group = "dagster";
      home = cfg.workspaceDir;
      createHome = true;
    };
    users.groups.dagster = { };

    systemd.services = {
      dagster-webserver = {
        description = "Dagster Webserver";
        after = [
          "network.target"
        ]
        ++ lib.mapAttrsToList (name: _: "dagster-code-${name}.service") cfg.codeServers;
        wantedBy = [ "multi-user.target" ];

        environment.DAGSTER_HOME = cfg.workspaceDir;

        serviceConfig = {
          ExecStart = lib.concatStringsSep " " (
            [
              (lib.getExe cfg.package)
              "--host"
              cfg.host
              "--port"
              (toString cfg.port)
            ]
            ++ ws.workspaceArgs
            ++ cfg.extraArgs
          );
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
        };
      };
    }
    // lib.mapAttrs' (
      name: cs:
      lib.nameValuePair "dagster-code-${name}" {
        description = "Dagster Code Server (${name})";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        environment.DAGSTER_HOME = cfg.workspaceDir;

        serviceConfig = {
          ExecStart = lib.concatStringsSep " " (ws.codeServerArgs name cs);
          User = "dagster";
          Group = "dagster";
          WorkingDirectory = cfg.workspaceDir;
          Restart = "on-failure";
          RestartSec = 5;

          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ cfg.workspaceDir ];
          PrivateTmp = true;
        };
      }
    ) cfg.codeServers;
  };
}
