{
  config,
  lib,
  pkgs,
  ...
}: let
  jsonFormat = pkgs.formats.json {};
  cfg = config.dotfiles.programming.opencode.cliSettings;
in {
  options.dotfiles.programming.opencode.cliSettings = lib.mkOption {
    inherit (jsonFormat) type;
    default = {
      "$schema" = "https://opencode.ai/v2/cli.json";
      theme = {
        name = "catppuccin";
        mode = "dark";
      };
      # The notifier supplies terminal alerts; avoid duplicate built-in ones.
      plugins = ["*" "-opencode.notifications"];
    };
    description = "OpenCode 2 terminal settings merged into writable cli.json at activation.";
  };

  config.home.activation.opencodeCliSettings = lib.hm.dag.entryAfter ["linkGeneration"] (
    lib.hm.generators.mkImpureConfigMerger {
      inherit pkgs;
      format = "json";
      empty = "{}";
      jqOperation = "$dynamic * $static";
      path = "${config.xdg.configHome}/opencode/cli.json";
      staticSettings = jsonFormat.generate "opencode-cli.json" cfg;
      mode = "600";
    }
  );
}
