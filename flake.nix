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
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        ./nix/formatter.nix
        ./nix/shell.nix
      ];

      flake = {
        overlays.default = import ./overlay.nix;
      };

      perSystem =
        { system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ (import ./overlay.nix) ];
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
