#!/usr/bin/env python3
"""Update all dagster packages atomically.

All dagster-* packages share the same release version and must be updated
together to avoid version mismatches.
"""

import logging
import subprocess
import sys
from pathlib import Path

log = logging.getLogger(__name__)

# All dagster packages that share the same version
DAGSTER_PACKAGES = [
    "dagster-shared",
    "dagster-pipes",
    "dagster",
    "dagster-graphql",
    "dagster-webserver",
    "dagster-duckdb",
    "dagster-postgres",
]


def run_nix_update(name: str) -> None:
    """Run nix-update for a single package."""
    args_file = Path(f"packages/{name}/nix-update-args")
    extra_args: list[str] = []
    if args_file.exists():
        extra_args = [
            stripped
            for line in args_file.read_text().splitlines()
            if (stripped := line.strip()) and not stripped.startswith("#")
        ]

    cmd = ["nix-update", "--flake", name, *extra_args]
    log.info("Running: %s", " ".join(cmd))
    result = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
    )
    if result.stdout:
        sys.stdout.write(result.stdout)
    if result.returncode != 0:
        log.error("nix-update failed for %s", name)
        sys.exit(1)


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(message)s")

    for name in DAGSTER_PACKAGES:
        pkg_dir = Path(f"packages/{name}")
        if not pkg_dir.exists():
            log.warning("Skipping %s (directory not found)", name)
            continue
        run_nix_update(name)

    log.info("All dagster packages updated successfully")


if __name__ == "__main__":
    main()
