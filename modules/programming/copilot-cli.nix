{
  inputs,
  pkgs,
  ...
}: {
  programs.github-copilot-cli = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.copilot-cli;
    enableMcpIntegration = true;
    mutableSettings = true;
    settings.autoUpdate = false;
  };
}
