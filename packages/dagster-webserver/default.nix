{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatchling,
  click,
  dagster,
  dagster-graphql,
  starlette,
  uvicorn,
  websockets,
}:

buildPythonPackage (finalAttrs: {
  pname = "dagster-webserver";
  version = "1.12.18";
  pyproject = true;

  src = fetchPypi {
    pname = "dagster_webserver";
    inherit (finalAttrs) version;
    hash = "sha256-GhgCyOeYu5k2kIQ41anVAA40FxerL36ar1l5k7uKxtQ=";
  };

  build-system = [ hatchling ];

  dependencies = [
    click
    dagster
    dagster-graphql
    starlette
    uvicorn
    websockets
  ];

  doCheck = false;

  pythonImportsCheck = [ "dagster_webserver" ];

  meta = {
    description = "Dagster webserver";
    homepage = "https://github.com/dagster-io/dagster";
    license = lib.licenses.asl20;
    mainProgram = "dagster-webserver";
  };
})
