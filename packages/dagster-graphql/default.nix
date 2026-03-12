{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatchling,
  dagster,
  gql,
  graphene,
  requests,
  requests-toolbelt,
  starlette,
}:

buildPythonPackage (finalAttrs: {
  pname = "dagster-graphql";
  version = "1.12.18";
  pyproject = true;

  src = fetchPypi {
    pname = "dagster_graphql";
    inherit (finalAttrs) version;
    hash = "sha256-/CIIoD9KyXqokAXnnzTpf5Ze/yyCGjLTLdxitmA+gvw=";
  };

  build-system = [ hatchling ];

  dependencies = [
    dagster
    gql
    graphene
    requests
    requests-toolbelt
    starlette
  ];

  doCheck = false;

  pythonImportsCheck = [ "dagster_graphql" ];

  meta = {
    description = "Dagster GraphQL API";
    homepage = "https://github.com/dagster-io/dagster";
    license = lib.licenses.asl20;
  };
})
