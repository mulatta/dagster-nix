# dagster-nix

Nix packages, overlay, and NixOS/Darwin modules for [Dagster](https://dagster.io/) 1.12.x.

## Packages

| Package | Description |
|---------|-------------|
| `dagster` | Orchestrator core + CLI + webserver |
| `dagster-webserver` | Webserver only |

```bash
# Run dagster dev server with a workspace
nix run github:mulatta/dagster-nix#dagster -- dev -w workspace.yaml

# Run webserver only
nix run github:mulatta/dagster-nix#dagster-webserver -- -w workspace.yaml
```

## Overlay

Add dagster packages to your nixpkgs Python package set:

```nix
{
  inputs.dagster-nix.url = "github:mulatta/dagster-nix";

  outputs = { dagster-nix, nixpkgs, ... }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ dagster-nix.overlays.default ];
      };
    in {
      # Now available as python packages
      # pkgs.python313Packages.dagster
      # pkgs.python313Packages.dagster-webserver
      # pkgs.python313Packages.dagster-graphql
      # pkgs.python313Packages.dagster-pipes
      # pkgs.python313Packages.dagster-shared
    };
}
```

## NixOS Module

```nix
{
  imports = [ dagster-nix.nixosModules.default ];

  services.dagster = {
    enable = true;
    port = 3000;

    # Option A: Load Python modules directly
    workspace.pythonModules = [ "my_project.definitions" ];

    # Option B: Connect to remote code servers via gRPC
    workspace.grpcServers = [
      { host = "worker-1"; port = 4266; locationName = "etl"; }
    ];

    # Option C: Provide your own workspace.yaml
    # workspaceFile = ./workspace.yaml;

    # Optional: Run code servers on the same machine
    codeServers.etl = {
      module = "my_etl.definitions";
      port = 4266;
    };
  };
}
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

## Test Workspaces

Example workspaces for testing:

```bash
# Minimal hello asset
DAGSTER_HOME=/tmp/dagster-hello \
  nix run .#dagster -- dev -w tests/hello/workspace.yaml

# OpenAlex API example (fetches top neuroscience papers)
DAGSTER_HOME=/tmp/dagster-openalex \
  nix run .#dagster -- dev -w tests/openalex/workspace.yaml
```
