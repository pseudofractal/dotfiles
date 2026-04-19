{...}: {
  imports = [
    ./mcps.nix
    #./tools
    ./skills
    ./rules
  ];

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;

    tui.theme = "catppuccin";

    settings = {
      logLevel = "INFO";
      plugin = [
        "opencode-openai-codex-auth@latest"
        "opencode-gemini-auth@latest"
        "@mohak34/opencode-notifier@latest"
      ];
    };
  };

  home.sessionVariables = {
    OPENCODE_EXPERIMENTAL = "true";
    OPENCODE_DISABLE_LSP_DOWNLOAD = "true";
    CODEX_INTERNAL_ORIGINATOR_OVERRIDE = "Codex Desktop";
  };
}
