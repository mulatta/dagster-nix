{
  description = "Dagster packages for Nix";

  inputs = {
    # keep-sorted start
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pyproject-build-systems.inputs.nixpkgs.follows = "nixpkgs";
    pyproject-build-systems.inputs.pyproject-nix.follows = "pyproject-nix";
    pyproject-build-systems.inputs.uv2nix.follows = "uv2nix";
    pyproject-build-systems.url = "github:pyproject-nix/build-system-pkgs";
    pyproject-nix.inputs.nixpkgs.follows = "nixpkgs";
    pyproject-nix.url = "github:pyproject-nix/pyproject.nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    uv2nix.inputs.nixpkgs.follows = "nixpkgs";
    uv2nix.inputs.pyproject-nix.follows = "pyproject-nix";
    uv2nix.url = "github:pyproject-nix/uv2nix";
    # keep-sorted end
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
        workspaceRoot = ./.;
      };

      overlay = workspace.mkPyprojectOverlay {
        sourcePreference = "wheel";
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      imports = [
        ./nix/formatter.nix
        ./nix/shell.nix
      ];

      flake =
        { withSystem, ... }:
        {
          nixosModules.default =
            { pkgs, ... }:
            {
              imports = [ ./modules/nixos.nix ];
              services.dagster.package = pkgs.lib.mkDefault (
                withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }: config.packages.dagster)
              );
            };
          darwinModules.default =
            { pkgs, ... }:
            {
              imports = [ ./modules/darwin.nix ];
              services.dagster.package = pkgs.lib.mkDefault (
                withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }: config.packages.dagster)
              );
            };
        };

      perSystem =
        { pkgs, ... }:
        let
          python = pkgs.python313;

          pyprojectOverrides = import ./nix/python-overrides.nix;

          pythonSet =
            (pkgs.callPackage inputs.pyproject-nix.build.packages {
              inherit python;
            }).overrideScope
              (
                pkgs.lib.composeManyExtensions [
                  inputs.pyproject-build-systems.overlays.default
                  overlay
                  pyprojectOverrides
                ]
              );

          venv = (pythonSet.mkVirtualEnv "dagster-env" workspace.deps.default).overrideAttrs {
            meta.mainProgram = "dagster";
            passthru.dagsterVersion = pythonSet.dagster.version;
          };
        in
        {
          packages = {
            default = venv;
            dagster = venv;
          };

          checks = {
            dagster = venv;
          }
          // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
            vmtest = import ./tests/vmtest.nix {
              inherit pkgs;
              dagsterPackage = venv;
            };
          };
        };
    };
}
