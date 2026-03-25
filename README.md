# dagster-nix

Nix package and NixOS/Darwin modules for [Dagster](https://dagster.io/).

Python dependencies managed by [uv](https://docs.astral.sh/uv/) + [uv2nix](https://github.com/pyproject-nix/uv2nix).

## Quick Start

```bash
# Run dagster dev server
nix run github:mulatta/dagster-nix -- dev -w workspace.yaml

# Check version
nix run github:mulatta/dagster-nix -- --version
```

The `dagster` package is a single virtualenv containing `dagster`, `dagster-daemon`, `dagster-webserver`, `dagster-graphql`, `dagster-postgres`, and `dagster-duckdb`.

## NixOS Module

```nix
{
  inputs.dagster-nix.url = "github:mulatta/dagster-nix";

  outputs = { dagster-nix, nixpkgs, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        dagster-nix.nixosModules.default
        {
          services.dagster = {
            enable = true;

            # PostgreSQL storage (enabled by default)
            # settings.storage.postgres.database = "dagster";

            # Workspace: which code locations to load
            workspace.pythonModules = [ "my_project.definitions" ];

            # Or connect to remote code servers
            # workspace.grpcServers = [
            #   { host = "worker-1"; port = 4266; locationName = "etl"; }
            # ];

            # Run code servers on the same machine
            codeServers.etl = {
              module = "my_etl.definitions";
              port = 4266;
            };
          };

          # PostgreSQL setup (module does NOT create this automatically)
          services.postgresql = {
            enable = true;
            ensureDatabases = [ "dagster" ];
            ensureUsers = [{ name = "dagster"; ensureDBOwnership = true; }];
          };
        }
      ];
    };
  };
}
```

### Services

`enable = true` starts both **webserver** and **daemon** by default:

| Service | Default | Description |
|---------|---------|-------------|
| `webserver` | enabled | UI + GraphQL API (port 3000) |
| `daemon` | enabled | Schedules, sensors, backfills |
| `codeServers.*` | per entry | gRPC code location servers |

Disable components for worker-only nodes:

```nix
services.dagster = {
  enable = true;
  webserver.enable = false;
  daemon.enable = false;
  codeServers.ml = {
    module = "ml_pipeline.definitions";
    port = 4267;
  };
};
```

### Settings

dagster.yaml is generated from `settings` or provided directly via `settingsFile`:

```nix
services.dagster = {
  # Option A: Declarative (default)
  settings = {
    storage.postgres = {
      host = "/run/postgresql";
      database = "dagster";
      user = "dagster";
    };
    telemetry.enabled = false;
    extraConfig = {
      # Arbitrary dagster.yaml keys
      compute_logs.module = "dagster.core.storage.noop_compute_log_manager";
    };
  };

  # Option B: Bring your own
  # settingsFile = ./dagster.yaml;

  # Secrets via environment file (sops-nix, agenix, etc.)
  # environmentFile = config.sops.secrets.dagster-env.path;
};
```

### Custom Package

Override the dagster package (e.g. from a pipeline repo using uv2nix):

```nix
services.dagster = {
  package = my-pipeline-venv;  # must include dagster + dagster-webserver
  codeServers.etl.package = my-pipeline-venv;  # code server can use same or different venv
};
```

## Darwin Module

```nix
{
  imports = [ dagster-nix.darwinModules.default ];

  services.dagster = {
    enable = true;
    workspace.pythonModules = [ "my_project.definitions" ];
  };
}
```

## Development

```bash
# Update Python dependencies
nix develop -c uv lock --upgrade

# Build
nix build

# Run tests
nix run .#dagster -- dev -w tests/hello/workspace.yaml
```
