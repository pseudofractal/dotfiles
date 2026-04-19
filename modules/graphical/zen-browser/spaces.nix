{lib, ...}: let
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

  # Zen Browser needs UUIDv4 for all of its IDs, but we want to generate them
  # deterministically based on the space name. This function creates a fake
  # UUIDv4 by hashing the input string and formatting it in the UUID structure.
  create-fake-uuid-v4 = input_string: let
    hash = builtins.hashString "sha256" input_string;
  in
    "${builtins.substring 0 8 hash}-"
    + "${builtins.substring 8 4 hash}-"
    + "4${builtins.substring 13 3 hash}-"
    + "8${builtins.substring 17 3 hash}-"
    + "${builtins.substring 20 12 hash}";
in {
  programs.zen-browser.profiles.main = {
    settings."zen.view.sidebar-expanded.max-width" = sidebarExpandedWidth;

    spaces = builtins.listToAttrs (lib.imap1 (
        idx: space: {
          name = space.name;
          value = {
            inherit (space) name icon;
            position = idx * 1000;
            id = create-fake-uuid-v4 "zen-browser-space:${space.name}";
          };
        }
      )
      rawSpaces);
  };
}
