{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.python313
          pkgs.uv
        ];
        env.UV_PYTHON_DOWNLOADS = "never";
      };
    };
}
