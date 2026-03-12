{ lib, pkgs, ... }:
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

    workspace = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            pythonModules = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Python modules to load as code locations (e.g. [\"my_project.definitions\"]).";
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
        Declarative workspace configuration. Generates a workspace.yaml
        and passes it via -w to dagster-webserver.
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

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra arguments passed to dagster-webserver.";
    };

    codeServers = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            package = lib.mkOption {
              type = lib.types.package;
              default = pkgs.python313Packages.dagster;
              defaultText = lib.literalExpression "pkgs.python313Packages.dagster";
              description = "The dagster package to use for this code server.";
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
  };
}
