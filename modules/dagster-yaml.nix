{
  cfg,
  lib,
  pkgs,
}:
let
  hasSettings = cfg.settings != null;
  hasSettingsFile = cfg.settingsFile != null;
  pg = if hasSettings then cfg.settings.storage.postgres else null;
  hasPg = pg != null;

  generatedConfig =
    let
      storageConfig =
        if hasPg then
          {
            storage.postgres.postgres_url.env = "DAGSTER_PG_URL";
          }
        else
          {
            storage.sqlite.base_dir = toString cfg.workspaceDir;
          };

      telemetryConfig = {
        telemetry.enabled = cfg.settings.telemetry.enabled;
      };

      runLauncherConfig = {
        run_launcher = cfg.settings.runLauncher;
      };

      retentionConfig = lib.optionalAttrs (cfg.settings.retention != null) {
        inherit (cfg.settings) retention;
      };

      base = storageConfig // telemetryConfig // runLauncherConfig // retentionConfig;
    in
    lib.recursiveUpdate base cfg.settings.extraConfig;

  dagsterYaml = pkgs.writeText "dagster.yaml" (builtins.toJSON generatedConfig);
in
{
  assertions = [
    {
      assertion = !(hasSettings && hasSettingsFile);
      message = "services.dagster: settings and settingsFile are mutually exclusive.";
    }
  ];

  # The dagster.yaml file path to symlink into workspaceDir
  configFile = if hasSettingsFile then cfg.settingsFile else dagsterYaml;

  # PostgreSQL connection URL for environment variable
  postgresUrl = lib.optionalString hasPg "postgresql://${pg.user}@/${pg.database}?host=${pg.host}";

  inherit hasPg;
}
