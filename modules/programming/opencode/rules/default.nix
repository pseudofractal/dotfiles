{config, lib, ...}: let
  ruleSources = {
    "general.md" = ./general.md;
  };

  instructionPaths = builtins.map (
    name: "${config.xdg.configHome}/opencode/rules/${name}"
  ) (builtins.attrNames ruleSources);
in {
  xdg.configFile =
    (lib.mapAttrs' (
      name: source: {
        name = "opencode/rules/${name}";
        value.source = source;
      }
    ) ruleSources)
    // {
      "opencode/config.json".text = builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";
        instructions = instructionPaths;
      };
    };
}
