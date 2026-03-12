# Overlay that adds dagster packages to pythonPackages sets
_final: prev:
let
  applyDagsterOverrides = python-final: _python-prev: {
    coloredlogs = python-final.callPackage ./packages/coloredlogs { };
    dagster-pipes = python-final.callPackage ./packages/dagster-pipes { };
    dagster-shared = python-final.callPackage ./packages/dagster-shared { };
    dagster = python-final.callPackage ./packages/dagster { };
    dagster-graphql = python-final.callPackage ./packages/dagster-graphql { };
    dagster-webserver = python-final.callPackage ./packages/dagster-webserver { };
  };
in
{
  python3Packages = prev.python3Packages.override {
    overrides = applyDagsterOverrides;
  };
  python313Packages = prev.python313Packages.override {
    overrides = applyDagsterOverrides;
  };
}
