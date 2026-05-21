{lib, ...}: let
  lua = lib.generators.mkLuaInline;
in {
  programs.nvf.settings.vim = {
    luaConfigPre = ''
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    '';

    mini = {
      ai.enable = true;
      bracketed.enable = true;
      clue = {
        enable = true;
        setupOpts = {
          triggers = [
            {
              mode = ["n" "x"];
              keys = "<Leader>";
            }
            {
              mode = "i";
              keys = "<C-x>";
            }
            {
              mode = ["n" "x"];
              keys = "g";
            }
            {
              mode = "n";
              keys = "[";
            }
            {
              mode = "n";
              keys = "]";
            }
            {
              mode = "n";
              keys = "<C-w>";
            }
            {
              mode = ["n" "x"];
              keys = "z";
            }
          ];

          clues = lua ''
            (function()
              local miniclue = require("mini.clue")

              return {
                miniclue.gen_clues.builtin_completion(),
                miniclue.gen_clues.g(),
                miniclue.gen_clues.square_brackets(),
                miniclue.gen_clues.windows(),
                miniclue.gen_clues.z(),

                { mode = "n", keys = "<Leader>b", desc = "+Buffer" },
                { mode = "n", keys = "<Leader>c", desc = "+Code" },
                { mode = "n", keys = "<Leader>f", desc = "+Find" },
                { mode = "n", keys = "<Leader>g", desc = "+Git" },
                { mode = "n", keys = "<Leader>j", desc = "+Jump" },
                { mode = "n", keys = "<Leader>l", desc = "+LSP" },
                { mode = "n", keys = "<Leader>t", desc = "+Toggle" },
                { mode = "n", keys = "<Leader>x", desc = "+Diagnostics" },
              }
            end)()
          '';

          window = {
            delay = 200;
            config = {
              width = "auto";
            };
          };
        };
      };
      comment.enable = true;

      hipatterns = {
        enable = true;
        setupOpts = {
          highlighters = {
            fixme = {
              pattern = "%f[%w]()FIXME()%f[%W]";
              group = "MiniHipatternsFixme";
            };
            hack = {
              pattern = "%f[%w]()HACK()%f[%W]";
              group = "MiniHipatternsHack";
            };
            todo = {
              pattern = "%f[%w]()TODO()%f[%W]";
              group = "MiniHipatternsTodo";
            };
            note = {
              pattern = "%f[%w]()NOTE()%f[%W]";
              group = "MiniHipatternsNote";
            };

            hex_color =
              lib.generators.mkLuaInline
              "require('mini.hipatterns').gen_highlighter.hex_color()";
          };
        };
      };

      icons.enable = true;
      # starter = {
      #   enable = true;
      #   setupOpts = lua ''require("nvf.starter").config()'';
      # };

      pairs = {
        enable = true;
        setupOpts.mappings = {
          "$" = {
            action = "closeopen";
            pair = "$$";
            neigh_pattern = "^[^%a\\]";
            register = {
              cr = false;
            };
          };
        };
      };

      # sessions = {
      #   enable = true;
      #   setupOpts = {
      #     autoread = false;
      #     autowrite = true;
      #     directory = lua ''require("nvf.project_sessions").session_directory()'';
      #     file = "";
      #     force = {
      #       read = true;
      #       write = true;
      #       delete = false;
      #     };
      #     verbose = {
      #       read = false;
      #       write = false;
      #       delete = true;
      #     };
      #   };
      # };

      statusline = {
        enable = true;
        setupOpts = {
          use_icons = true;
        };
      };

      surround = {
        enable = true;
      };
    };
  };
}
