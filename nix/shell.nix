{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.uv
        ];
        env.UV_PYTHON_DOWNLOADS = "never";
      };
    };
}
