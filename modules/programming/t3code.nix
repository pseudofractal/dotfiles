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
      }
      // lib.genAttrs ["cursor" "grok" "muse" "pi" "antigravity"] (driver: {
        inherit driver;
        enabled = false;
        config.enabled = false;
      });
  };
}
