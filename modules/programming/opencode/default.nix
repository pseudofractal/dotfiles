{...}: {
  imports = [
    # keep-sorted start
    #./tools
    ./mcps.nix
    ./rules
    ./skills
    # keep-sorted end
  ];

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;

    tui.theme = "catppuccin";

    settings = {
      logLevel = "INFO";
      plugin = [
        # keep-sorted start
        "@mohak34/opencode-notifier@latest"
        "opencode-gemini-auth@latest"
        "opencode-openai-codex-auth@latest"
        # keep-sorted end
      ];
    };
  };

  home.sessionVariables = {
    OPENCODE_EXPERIMENTAL = "true";
    OPENCODE_DISABLE_LSP_DOWNLOAD = "true";
    CODEX_INTERNAL_ORIGINATOR_OVERRIDE = "Codex Desktop";
  };
}
