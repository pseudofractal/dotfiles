{
  config,
  inputs,
  isAndroid,
  lib,
  pkgs,
  ...
}: let
  nightly = inputs.t3code.packages.${pkgs.stdenv.hostPlatform.system}.t3code-nightly;
  # Desktop launchers do not inherit Fish's PATH. Keep the same CLI and
  # language-server environment available when launching from the app menu.
  package = pkgs.symlinkJoin {
    name = "t3code-nightly-${nightly.version}";
    inherit (nightly) version meta;
    paths = [nightly];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      for program in t3code t3; do
        wrapProgram "$out/bin/$program" \
          --prefix PATH : ${lib.escapeShellArg "${config.home.profileDirectory}/bin:${lib.makeBinPath [pkgs.git pkgs.openssh]}"}
      done
    '';
  };
  enabledProvider = driver: binaryPath: {
    inherit driver;
    enabled = true;
    config = {
      inherit binaryPath;
      enabled = true;
    };
  };
  # T3 gives Antigravity a private GEMINI_HOME and deliberately does not link
  # ~/.gemini/config/mcp_config.json into it (pingdotgg/t3code#42608). Link the
  # shared MCP config into the profile before each launch. T3 already links the
  # shared skills and AGENTS.md itself. The wrapper must be named `agy` because
  # T3 only accepts custom Antigravity executables with that basename.
  antigravityT3 = pkgs.writeShellApplication {
    name = "agy";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      if [ -n "''${GEMINI_HOME:-}" ] && [ -f "$HOME/.gemini/config/mcp_config.json" ]; then
        mkdir -p "$GEMINI_HOME/config"
        ln -sfn "$HOME/.gemini/config/mcp_config.json" "$GEMINI_HOME/config/mcp_config.json"
      fi
      exec ${lib.getExe pkgs.antigravity-cli} "$@"
    '';
  };
in {
  programs.t3code = lib.mkIf (!isAndroid) {
    enable = true;
    inherit package;
    mutableUserSettings = true;
    mutableClientSettings = true;
    mutableKeybindings = true;
    userSettings.providerInstances =
      {
        codex = enabledProvider "codex" (lib.getExe config.programs.codex.package);
        claudeAgent = enabledProvider "claudeAgent" (lib.getExe config.programs.claude-code.finalPackage);
        opencode = enabledProvider "opencode" (lib.getExe config.programs.opencode.package);
        antigravity = {
          driver = "antigravity";
          enabled = true;
          config = {
            enabled = true;
            authMethod = "oauth-personal";
            binaryPath = lib.getExe antigravityT3;
          };
        };
      }
      // lib.genAttrs ["cursor" "grok" "muse" "pi"] (driver: {
        inherit driver;
        enabled = false;
        config.enabled = false;
      });
  };
}
