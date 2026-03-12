{
  lib,
  buildPythonPackage,
  fetchurl,
  alembic,
  antlr4-python3-runtime,
  click,
  coloredlogs,
  dagster-pipes,
  dagster-shared,
  docstring-parser,
  filelock,
  grpcio,
  grpcio-health-checking,
  jinja2,
  protobuf,
  python-dotenv,
  pytz,
  requests,
  rich,
  setuptools,
  six,
  sqlalchemy,
  structlog,
  tabulate,
  tomli,
  toposort,
  tqdm,
  tzdata,
  universal-pathlib,
  watchdog,
}:

buildPythonPackage (finalAttrs: {
  pname = "dagster";
  version = "1.12.18";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/py3/d/dagster/dagster-${finalAttrs.version}-py3-none-any.whl";
    hash = "sha256-/+zdTtP4X2NRS7ee8j0UBNOYH55UQAdVPLQEZbC8JKE=";
  };

  dependencies = [
    alembic
    antlr4-python3-runtime
    click
    coloredlogs
    dagster-pipes
    dagster-shared
    docstring-parser
    filelock
    grpcio
    grpcio-health-checking
    jinja2
    protobuf
    python-dotenv
    pytz
    requests
    rich
    setuptools
    six
    sqlalchemy
    structlog
    tabulate
    tomli
    toposort
    tqdm
    tzdata
    universal-pathlib
    watchdog
  ];

  doCheck = false;

  pythonImportsCheck = [ "dagster" ];

  meta = {
    description = "Dagster — an orchestrator for the whole development lifecycle";
    homepage = "https://github.com/dagster-io/dagster";
    license = lib.licenses.asl20;
    mainProgram = "dagster";
  };
})
