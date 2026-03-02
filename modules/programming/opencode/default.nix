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

    settings = {
      theme = "catppuccin";
      logLevel = "INFO";
    };
  };

  home.sessionVariables = {
    OPENCODE_EXPERIMENTAL = "true";
    OPENCODE_DISABLE_LSP_DOWNLOAD = "true";
  };
}
