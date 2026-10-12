{lib, ...}: let
  inherit (import ./uuid.nix) uuidV4FromName;
  rawSpaces = [
    {
      name = "General";
      icon = "🏠";
    }
    {
      name = "Studies";
      icon = "📚";
    }
    {
      name = "Thesis";
      icon = "🪩";
    }
    {
      name = "Coding";
      icon = "💼";
    }
    {
      name = "Research";
      icon = "📃";
    }
    {
      name = "Rice";
      icon = "🍚";
    }
    {
      name = "Entertainment";
      icon = "🎮";
    }
  ];

  sidebarExpandedWidth = builtins.length rawSpaces * (16 + (16 * 2));
in {
  programs.zen-browser.profiles.main = {
    settings."zen.view.sidebar-expanded.max-width" = sidebarExpandedWidth;

    spaces = builtins.listToAttrs (lib.imap1 (
        idx: space: {
          name = space.name;
          value = {
            inherit (space) name icon;
            position = idx * 1000;
            id = uuidV4FromName "zen-browser-space:${space.name}";
          };
        }
      )
      rawSpaces);
  };
}
