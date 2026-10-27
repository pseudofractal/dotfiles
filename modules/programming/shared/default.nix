{
  config,
  lib,
  ...
}: let
  cfg = config.dotfiles.programming.agents;
in {
  imports = [./mcps.nix ./skills.nix];

  options.dotfiles.programming.agents = {
    instructions = lib.mkOption {
      type = lib.types.lines;
      default = builtins.readFile ./instructions.md;
      description = "Global instructions shared by OpenCode, Codex, and Claude Code.";
    };
    skills = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = {};
      description = "Named skill directories or SKILL.md content installed for all three agents.";
    };
  };

  config = {
    # The rubric front matter and instructions are concatenated into one
    # SKILL.md; coding-style.md holds everything up to the "## Review rubric"
    # heading, instructions.md the sections below it. The "\n" restores the
    # blank line mdformat strips from the end of coding-style.md.
    dotfiles.programming.agents.skills.coding-style =
      builtins.readFile ./coding-style.md
      + "\n"
      + cfg.instructions;

    xdg.configFile."coding-agents/AGENTS.md".text = cfg.instructions;
    programs.opencode = {
      skills = cfg.skills;
      settings.instructions = ["${config.xdg.configHome}/coding-agents/AGENTS.md"];
    };
    programs.codex = {
      context = cfg.instructions;
      skills = cfg.skills;
    };
    programs.claude-code = {
      context = cfg.instructions;
      skills = cfg.skills;
    };
  };
}
