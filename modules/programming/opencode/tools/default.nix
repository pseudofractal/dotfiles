{lib, ...}: let
  toolSources = {};
in {
  xdg.configFile =
    lib.mapAttrs' (
      name: source: {
        name = "opencode/tools/${name}";
        value.source = source;
      }
    )
    toolSources;
}
