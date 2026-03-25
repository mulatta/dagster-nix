{
  cfg,
  lib,
  pkgs,
}:
let
  # Build workspace.yaml content from declarative config
  workspaceYaml =
    let
      moduleEntries = map (m: { python_module = m; }) cfg.workspace.pythonModules;
      fileEntries = map (f: { python_file = toString f; }) cfg.workspace.pythonFiles;
      grpcEntries = map (s: {
        grpc_server = {
          inherit (s) host port;
        }
        // lib.optionalAttrs (s.locationName != null) { location_name = s.locationName; };
      }) cfg.workspace.grpcServers;
      allEntries = moduleEntries ++ fileEntries ++ grpcEntries;
    in
    assert allEntries != [ ];
    {
      load_from = allEntries;
    };

  workspaceFile = pkgs.writeText "workspace.yaml" (builtins.toJSON workspaceYaml);

  hasWorkspace = cfg.workspace != null;
  hasWorkspaceFile = cfg.workspaceFile != null;
  needsWorkspace = cfg.webserver.enable || cfg.daemon.enable;
in
{
  codeServerAssertions = lib.mapAttrsToList (name: cs: {
    assertion = (cs.module != null) != (cs.pythonFile != null);
    message = "services.dagster.codeServers.${name}: exactly one of module or pythonFile must be set.";
  }) cfg.codeServers;

  assertions = [
    {
      assertion = !(hasWorkspace && hasWorkspaceFile);
      message = "services.dagster: workspace and workspaceFile are mutually exclusive.";
    }
    {
      assertion = !needsWorkspace || hasWorkspace || hasWorkspaceFile;
      message = "services.dagster: either workspace or workspaceFile must be set when webserver or daemon is enabled.";
    }
    {
      assertion =
        !hasWorkspace
        || (
          cfg.workspace.pythonModules != [ ]
          || cfg.workspace.pythonFiles != [ ]
          || cfg.workspace.grpcServers != [ ]
        );
      message = "services.dagster.workspace: at least one of pythonModules, pythonFiles, or grpcServers must be set.";
    }
  ]
  ++ codeServerAssertions;

  workspaceArgs =
    if hasWorkspaceFile then
      [
        "-w"
        (toString cfg.workspaceFile)
      ]
    else if hasWorkspace then
      [
        "-w"
        (toString workspaceFile)
      ]
    else
      [ ];

  # Build command-line args for a code server instance
  codeServerArgs =
    name: cs:
    [
      (lib.getExe cs.package)
      "code-server"
      "start"
      "--host"
      cs.host
      "--port"
      (toString cs.port)
      "--location-name"
      name
    ]
    ++ lib.optionals (cs.module != null) [
      "-m"
      cs.module
    ]
    ++ lib.optionals (cs.pythonFile != null) [
      "-f"
      (toString cs.pythonFile)
    ]
    ++ lib.optionals (cs.workingDirectory != null) [
      "-d"
      cs.workingDirectory
    ]
    ++ lib.optionals (cs.maxWorkers != null) [
      "-n"
      (toString cs.maxWorkers)
    ]
    ++ cs.extraArgs;
}
