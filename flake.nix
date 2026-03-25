{
  description = "Dagster packages for Nix";

  inputs = {
    # keep-sorted start
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    # keep-sorted end
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      overrides = python-final: _python-prev: {
        coloredlogs = python-final.callPackage ./packages/coloredlogs { };
        dagster-pipes = python-final.callPackage ./packages/dagster-pipes { };
        dagster-shared = python-final.callPackage ./packages/dagster-shared { };
        dagster = python-final.callPackage ./packages/dagster { };
        dagster-graphql = python-final.callPackage ./packages/dagster-graphql { };
        dagster-webserver = python-final.callPackage ./packages/dagster-webserver { };
        dagster-duckdb = python-final.callPackage ./packages/dagster-duckdb { };
        dagster-postgres = python-final.callPackage ./packages/dagster-postgres { };
      };

      dagsterOverlay = _final: prev: {
        python3 = prev.python3.override { packageOverrides = overrides; };
        python313 = prev.python313.override { packageOverrides = overrides; };
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        ./nix/formatter.nix
        ./nix/shell.nix
      ];

      flake = {
        overlays.default = dagsterOverlay;
        nixosModules.default = ./modules/nixos.nix;
        darwinModules.default = ./modules/darwin.nix;
      };

      perSystem =
        { system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ dagsterOverlay ];
          };
          py = pkgs.python313Packages;

          # Runnable apps with proper sys.executable via withPackages
          mkDagsterApp =
            mainProgram: deps:
            (pkgs.python313.withPackages (_ps: deps)).overrideAttrs {
              inherit (builtins.head deps) version;
              meta.mainProgram = mainProgram;
            };
        in
        {
          _module.args.pkgs = pkgs;

          packages = {
            default = mkDagsterApp "dagster" [
              py.dagster
              py.dagster-webserver
            ];
            dagster = mkDagsterApp "dagster" [
              py.dagster
              py.dagster-webserver
            ];
            dagster-webserver = mkDagsterApp "dagster-webserver" [ py.dagster-webserver ];
          };

          checks = {
            inherit (py)
              dagster
              dagster-pipes
              dagster-shared
              dagster-graphql
              dagster-webserver
              dagster-duckdb
              dagster-postgres
              ;
          };
        };
    };
}
