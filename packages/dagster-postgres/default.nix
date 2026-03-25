{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatchling,
  dagster,
  psycopg2,
}:

buildPythonPackage (finalAttrs: {
  pname = "dagster-postgres";
  version = "0.28.18";
  pyproject = true;

  src = fetchPypi {
    pname = "dagster_postgres";
    inherit (finalAttrs) version;
    hash = "sha256-ksHxxew7hnJS0TyWUnyEl4l+R/FRsZ1wpbKLmjV+WIQ=";
  };

  build-system = [ hatchling ];

  dependencies = [
    dagster
    psycopg2
  ];

  # psycopg2 in nixpkgs provides psycopg2-binary functionality
  pythonRelaxDeps = [ "psycopg2-binary" ];
  pythonRemoveDeps = [ "psycopg2-binary" ];

  doCheck = false;

  pythonImportsCheck = [ "dagster_postgres" ];

  meta = {
    description = "Dagster integration for PostgreSQL";
    homepage = "https://github.com/dagster-io/dagster";
    license = lib.licenses.asl20;
  };
})
