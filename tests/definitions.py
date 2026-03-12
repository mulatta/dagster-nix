from dagster import Definitions, asset


@asset
def hello():
    """A minimal test asset."""
    return "hello dagster"


defs = Definitions(assets=[hello])
