{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  humanfriendly,
}:

buildPythonPackage (finalAttrs: {
  pname = "coloredlogs";
  version = "14.0";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-ofqxk9IFOqbAqXYIxDQtAx8fk6PRIYQyxZMiRB0xpQU=";
  };

  build-system = [ setuptools ];

  dependencies = [ humanfriendly ];

  # Tests require virtualenv
  doCheck = false;

  pythonImportsCheck = [ "coloredlogs" ];

  meta = {
    description = "Colored terminal output for Python's logging module";
    homepage = "https://coloredlogs.readthedocs.io";
    license = lib.licenses.mit;
  };
})
