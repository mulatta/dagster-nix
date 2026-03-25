{
  pkgs,
  dagsterPackage,
}:
let
  # Minimal dagster definitions for testing
  testDefinitions = pkgs.writeText "definitions.py" ''
    from dagster import Definitions, asset

    @asset
    def hello():
        return "hello dagster"

    defs = Definitions(assets=[hello])
  '';
in
pkgs.testers.runNixOSTest {
  name = "dagster";

  nodes.full = {
    virtualisation = {
      cores = 2;
      memorySize = 2048;
    };

    imports = [ ../modules/nixos.nix ];

    services.dagster = {
      enable = true;
      package = dagsterPackage;
      workspace.pythonFiles = [ testDefinitions ];

      codeServers.hello = {
        pythonFile = testDefinitions;
        port = 4266;
      };
    };
  };

  nodes.worker = {
    virtualisation = {
      cores = 1;
      memorySize = 1024;
    };

    imports = [ ../modules/nixos.nix ];

    services.dagster = {
      enable = true;
      package = dagsterPackage;
      webserver.enable = false;
      daemon.enable = false;
      settings.storage.postgres.createLocally = false;
      workspace.pythonFiles = [ testDefinitions ];
    };
  };

  testScript = ''
    start_all()

    # === full node: default config with all components ===

    with subtest("PostgreSQL starts and dagster database exists"):
        full.wait_for_unit("postgresql.service")
        full.wait_for_unit("postgresql-setup.service")
        full.succeed("sudo -u postgres psql -lqt | grep -q dagster")
        full.succeed("sudo -u postgres psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='dagster'\" | grep -q 1")

    with subtest("dagster.yaml is generated with correct content"):
        full.succeed("test -L /var/lib/dagster/dagster.yaml")
        full.succeed("grep -q postgres /var/lib/dagster/dagster.yaml")
        full.succeed("grep -q 'enabled: false' /var/lib/dagster/dagster.yaml")  # telemetry off

    with subtest("webserver starts and responds"):
        full.wait_for_unit("dagster-webserver.service")
        full.wait_for_open_port(3000)
        full.succeed("curl -sf http://localhost:3000/server_info | grep -q dagster")

    with subtest("daemon starts"):
        full.wait_for_unit("dagster-daemon.service")

    with subtest("code server starts"):
        full.wait_for_unit("dagster-code-hello.service")
        full.wait_for_open_port(4266)

    # === worker node: webserver/daemon disabled, no local postgres ===

    with subtest("worker has no postgresql"):
        worker.fail("systemctl is-active postgresql.service")

    with subtest("worker has no webserver or daemon"):
        worker.fail("systemctl cat dagster-webserver.service")
        worker.fail("systemctl cat dagster-daemon.service")
  '';
}
