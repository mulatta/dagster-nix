{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatchling,
  packaging,
  platformdirs,
  pydantic,
  pyyaml,
  tomlkit,
  typing-extensions,
}:

buildPythonPackage (finalAttrs: {
  pname = "dagster-shared";
  version = "1.12.18";
  pyproject = true;

  src = fetchPypi {
    pname = "dagster_shared";
    inherit (finalAttrs) version;
    hash = "sha256-tDrslCPpu9jtzxr2pT3hkHZUgDmH31bax2YstIbccQQ=";
  };

  build-system = [ hatchling ];

  dependencies = [
    packaging
    platformdirs
    pydantic
    pyyaml
    tomlkit
    typing-extensions
  ];

  pythonImportsCheck = [ "dagster_shared" ];

  meta = {
    description = "Dagster shared utilities";
    homepage = "https://github.com/dagster-io/dagster";
    license = lib.licenses.asl20;
  };
})
