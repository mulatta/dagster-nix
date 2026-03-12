{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatchling,
}:

buildPythonPackage (finalAttrs: {
  pname = "dagster-pipes";
  version = "1.12.18";
  pyproject = true;

  src = fetchPypi {
    pname = "dagster_pipes";
    inherit (finalAttrs) version;
    hash = "sha256-p+/+qEnwsVlxP5OffbtqtcBjtz6+Y1MAwKphvvnXCNA=";
  };

  build-system = [ hatchling ];

  pythonImportsCheck = [ "dagster_pipes" ];

  meta = {
    description = "Dagster Pipes — protocol for launching and interacting with external processes";
    homepage = "https://github.com/dagster-io/dagster";
    license = lib.licenses.asl20;
  };
})
