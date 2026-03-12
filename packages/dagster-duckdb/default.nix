{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatchling,
  dagster,
  duckdb,
}:

buildPythonPackage (finalAttrs: {
  pname = "dagster-duckdb";
  version = "0.28.18";
  pyproject = true;

  src = fetchPypi {
    pname = "dagster_duckdb";
    inherit (finalAttrs) version;
    hash = "sha256-FwDw7g39sotcVS9R/QEEetvJdg8Q+JEzyfCn+1T+zhg=";
  };

  build-system = [ hatchling ];

  dependencies = [
    dagster
    duckdb
  ];

  doCheck = false;

  pythonImportsCheck = [ "dagster_duckdb" ];

  meta = {
    description = "Dagster integration for DuckDB";
    homepage = "https://github.com/dagster-io/dagster";
    license = lib.licenses.asl20;
  };
})
