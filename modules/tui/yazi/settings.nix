{config, lib, ...}: let
  inherit (lib.attrsets) cartesianProduct;
  inherit (lib.lists) concatLists;
  username = config.home.username;
in {
  programs.yazi.settings = {
    mgr = {
      ratio = [1 1 2];
      sort_by = "natural";
      sort_dir_first = true;
      linemode = "permissions";
      show_hidden = true;
      show_symlink = true;
    };

    preview = {
      tab_size = 2;
      cache_dir = "";
      image_filter = "catmull-rom";
      image_quality = 90;
      sixel_fraction = 15;
      ueberzug_scale = 1;
      ueberzug_offset = [0 0 0 0];
      max_height = 1000;
      max_width = 1000;
    };

    plugin = {
      # prepend_fetchers = [
      #   {
      #     id = "git";
      #     name = "*";
      #     run = "git";
      #   }
      #   {
      #     id = "git";
      #     name = "*/";
      #     run = "git";
      #   }
      # ];

      prepend_preloaders = [
        {
          url = "/run/user/1000/gvfs/**/*";
          run = "noop";
        }
        {
          url = "/run/media/${username}/**/*";
          run = "noop";
        }
        {
          mime = "{audio,video,image}/*";
          run = "mediainfo";
        }
        {
          mime = "application/subrip";
          run = "mediainfo";
        }
      ];

      prepend_previewers = [
        {
          url = "*.md";
          run = "enhance-piper -- CLICOLOR_FORCE=1 glow -w=$w -s=dark \"$1\"";
        }
        {
          url = "/run/user/1000/gvfs/**/*";
          run = "noop";
        }
        {
          url = "/run/media/${username}/**/*";
          run = "noop";
        }
        {
          mime = "{audio,video,image}/*";
          run = "mediainfo";
        }
        {
          mime = "application/subrip";
          run = "mediainfo";
        }
        {
          mime = "application/{openxmlformats-officedocument.*,oasis.opendocument.*,ms-*,msword}";
          run = "office";
        }
        {
          mime = "application/{*zip,*tar,*rar,x-bzip2,x-7z-compressed,x-xz}";
          run = "enhance-piper -- ouch list -tA \"$1\"";
        }
        {
          mime = "text/*";
          run = "code";
        }
        {
          mime = "*/xml";
          run = "code";
        }
        {
          mime = "*/javascript";
          run = "code";
        }
        {
          mime = "*/x-wine-extension-ini";
          run = "code";
        }
      ];

      prepend_spotters = [
        {
          url = "*";
          run = "file-extra-metadata";
        }
      ];
    };

    open.prepend_rules = [
      {
        mime = "text/*";
        use = ["edit" "open" "reveal"];
      }
      {
        mime = "inode/empty";
        use = ["edit" "open" "reveal"];
      }
      {
        mime = "application/json";
        use = ["open" "edit" "reveal"];
      }
      {
        mime = "application/pdf";
        use = ["open" "reveal"];
      }
      {
        mime = "application/{*zip,*tar,*rar,x-bzip2,x-7z-compressed,x-xz}";
        use = ["extract" "reveal"];
      }
      {
        mime = "folder/local";
        use = ["open" "reveal"];
      }
      {
        mime = "vfs/{absent,stale}";
        use = ["download"];
      }
      {
        url = "*";
        use = ["open" "reveal"];
      }
    ];
  };
}
