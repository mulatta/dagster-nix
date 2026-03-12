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
      };

      dagsterOverlay = _final: prev: {
        python3Packages = prev.python3Packages.override { inherit overrides; };
        python313Packages = prev.python313Packages.override { inherit overrides; };
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
      };

      perSystem =
        { system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ dagsterOverlay ];
          };
          py = pkgs.python313Packages;
        in
        {
          _module.args.pkgs = pkgs;

          packages = {
            default = py.dagster;
            inherit (py) dagster;
            inherit (py) dagster-pipes;
            inherit (py) dagster-shared;
            inherit (py) dagster-graphql;
            inherit (py) dagster-webserver;
          };
        };
    };
}
