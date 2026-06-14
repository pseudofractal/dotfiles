{lib, ...}: let
  skillSources = {
    "frontend-design" = ./frontend-design.md;
    "web-fetch" = ./web-fetch.md;
  };
in {
  xdg.configFile =
    lib.mapAttrs' (
      name: source: {
        name = "opencode/skills/${name}/SKILL.md";
        value.source = source;
      }
    )
    skillSources;
}
