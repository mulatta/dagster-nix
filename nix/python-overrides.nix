# Build fixups for Python packages that need special handling.
# Add overrides here when uv2nix packages fail to build
# (missing build systems, C library dependencies, etc.)
_final: _prev: {
  # Example:
  # some-package = prev.some-package.overrideAttrs (old: {
  #   nativeBuildInputs = old.nativeBuildInputs ++ [ final.setuptools ];
  # });
}
