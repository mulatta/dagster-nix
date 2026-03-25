{ config, lib, ... }:
let
  cfg = config.services.dagster;
in
{
  options.services.dagster = {
    enable = lib.mkEnableOption "Dagster orchestration platform";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The dagster virtualenv package (provides dagster, dagster-daemon, dagster-webserver).";
    };

    workspaceDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/dagster";
      description = "Dagster home directory (DAGSTER_HOME) for storage and runtime data.";
    };

    # dagster.yaml — bring-your-own or generated from settings
    settingsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a dagster.yaml file. Mutually exclusive with settings.
        When set, this file is symlinked into workspaceDir as dagster.yaml.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            storage.postgres = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.submodule {
                  options = {
                    createLocally = lib.mkEnableOption "automatic local PostgreSQL database and user creation" // {
                      default = true;
                    };
                    host = lib.mkOption {
                      type = lib.types.str;
                      default = "/run/postgresql";
                      description = "PostgreSQL host or Unix socket directory.";
                    };
                    database = lib.mkOption {
                      type = lib.types.str;
                      default = "dagster";
                      description = "PostgreSQL database name.";
                    };
                    user = lib.mkOption {
                      type = lib.types.str;
                      default = "dagster";
                      description = "PostgreSQL user.";
                    };
                  };
                }
              );
              default = { };
              description = ''
                PostgreSQL storage configuration. Enabled by default for production use.
                Set to null to fall back to SQLite (not recommended for production).
              '';
            };

            telemetry.enabled = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether to enable Dagster telemetry.";
            };

            runLauncher = lib.mkOption {
              type = lib.types.attrs;
              default = {
                module = "dagster._core.launcher.default_run_launcher";
                class = "DefaultRunLauncher";
                config = { };
              };
              description = "Run launcher configuration for dagster.yaml.";
            };

            retention = lib.mkOption {
              type = lib.types.nullOr lib.types.attrs;
              default = null;
              description = "Retention/purge configuration for dagster.yaml.";
            };

            extraConfig = lib.mkOption {
              type = lib.types.attrs;
              default = { };
              description = ''
                Extra configuration merged into dagster.yaml.
                Useful for compute_logs, run_monitoring, etc.
              '';
            };
          };
        }
      );
      default = { };
      description = ''
        Declarative dagster.yaml configuration. Mutually exclusive with settingsFile.
        When null, no dagster.yaml is generated (use settingsFile instead).
      '';
    };

    # webserver
    webserver = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable the Dagster webserver (UI + GraphQL API).";
      };

      package = lib.mkOption {
        type = lib.types.package;
        description = "The dagster-webserver package to use. Defaults to the top-level dagster package.";
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

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra arguments passed to dagster-webserver.";
      };
    };

    # daemon
    daemon = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable the Dagster daemon (schedules, sensors, backfills).";
      };

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra arguments passed to dagster-daemon run.";
      };
    };

    # workspace
    workspace = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            pythonModules = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Python modules to load as code locations.";
            };

            pythonFiles = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              default = [ ];
              description = "Python files to load as code locations.";
            };

            grpcServers = lib.mkOption {
              type = lib.types.listOf (
                lib.types.submodule {
                  options = {
                    host = lib.mkOption {
                      type = lib.types.str;
                      default = "localhost";
                      description = "gRPC server host.";
                    };
                    port = lib.mkOption {
                      type = lib.types.port;
                      description = "gRPC server port.";
                    };
                    locationName = lib.mkOption {
                      type = lib.types.nullOr lib.types.str;
                      default = null;
                      description = "Optional name for this code location.";
                    };
                  };
                }
              );
              default = [ ];
              description = "Remote gRPC code servers to connect to.";
            };
          };
        }
      );
      default = null;
      description = ''
        Declarative workspace configuration. Generates a workspace.yaml.
        Cannot be used together with workspaceFile.
      '';
    };

    workspaceFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a workspace.yaml file.
        Cannot be used together with workspace.
      '';
    };

    # code servers
    codeServers = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            package = lib.mkOption {
              type = lib.types.package;
              default = cfg.package;
              defaultText = lib.literalExpression "config.services.dagster.package";
              description = "The dagster package for this code server. Defaults to the top-level dagster package.";
            };

            host = lib.mkOption {
              type = lib.types.str;
              default = "127.0.0.1";
              description = "Host to bind the gRPC code server to.";
            };

            port = lib.mkOption {
              type = lib.types.port;
              description = "Port for the gRPC code server.";
            };

            module = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Python module to serve (mutually exclusive with pythonFile).";
            };

            pythonFile = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = "Python file to serve (mutually exclusive with module).";
            };

            workingDirectory = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Working directory for the code server.";
            };

            maxWorkers = lib.mkOption {
              type = lib.types.nullOr lib.types.ints.positive;
              default = null;
              description = "Maximum number of threaded workers.";
            };

            environment = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
              description = ''
                Extra environment variables for this code server.
                Useful for LD_LIBRARY_PATH (GPU/CUDA), CUDA_VISIBLE_DEVICES, etc.
              '';
              example = lib.literalExpression ''
                {
                  LD_LIBRARY_PATH = lib.makeLibraryPath [
                    "''${pkgs.addDriverRunpath.driverLink}/lib"
                    pkgs.stdenv.cc.cc.lib
                  ];
                }
              '';
            };

            extraArgs = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Extra arguments passed to dagster code-server start.";
            };
          };
        }
      );
      default = { };
      description = ''
        Named code server instances. Each entry creates a separate
        dagster code-server process serving one code location via gRPC.
      '';
    };

    # secrets
    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "File containing environment variables loaded by all dagster services.";
    };
  };
}
