{...}: {
  programs.nvf.settings.vim.keymaps = [
    # General
    {
      key = "<leader>w";
      mode = "n";
      action = "<cmd>w<cr>";
      desc = "Save";
    }
    {
      key = "<leader>q";
      mode = "n";
      action = "<cmd>q<cr>";
      desc = "Quit";
    }

    # Buffers
    {
      key = "<leader>bb";
      mode = "n";
      action = "<cmd>Telescope buffers<cr>";
      desc = "Buffers";
    }
    {
      key = "<leader>bn";
      mode = "n";
      action = "<cmd>enew<cr>";
      desc = "New Buffer";
    }
    {
      key = "<leader>bd";
      mode = "n";
      action = "<cmd>bdelete<cr>";
      desc = "Delete Buffer";
    }

    # Find
    {
      key = "<leader>ff";
      mode = "n";
      action = "<cmd>Telescope find_files<cr>";
      desc = "Files";
    }
    {
      key = "<leader>fg";
      mode = "n";
      action = "<cmd>Telescope live_grep<cr>";
      desc = "Grep";
    }
    {
      key = "<leader>fo";
      mode = "n";
      action = "<cmd>Telescope oldfiles<cr>";
      desc = "Recent Files";
    }
    {
      key = "<leader>fr";
      mode = "n";
      action = "<cmd>Telescope resume<cr>";
      desc = "Resume Search";
    }
    {
      key = "<leader>fh";
      mode = "n";
      action = "<cmd>Telescope help_tags<cr>";
      desc = "Help";
    }
    {
      key = "<leader>fk";
      mode = "n";
      action = "<cmd>Telescope keymaps<cr>";
      desc = "Keymaps";
    }
    {
      key = "<leader>/";
      mode = "n";
      action = "<cmd>Telescope current_buffer_fuzzy_find<cr>";
      desc = "Buffer Search";
    }

    # Open
    {
      key = "<leader>oe";
      mode = "n";
      action = "<cmd>Yazi cwd<cr>";
      desc = "Explorer";
    }
    {
      key = "-";
      mode = ["n" "v"];
      action = "<cmd>Yazi<cr>";
      desc = "Yazi";
    }
    {
      key = "<leader>ot";
      mode = "n";
      lua = true;
      action = ''
        function()
          require("nvf.terminal").toggle()
        end
      '';
      desc = "Terminal";
    }

    {
      key = "<leader>oT";
      mode = "n";
      lua = true;
      action = ''
        function()
          require("nvf.terminal").new()
        end
      '';
      desc = "New Terminal";
    }

    {
      key = "<leader>or";
      mode = "n";
      lua = true;
      action = ''
        function()
          require("nvf.terminal").run_command()
        end
      '';
      desc = "Run Command";
    }

    # Code
    {
      key = "<leader>ca";
      mode = "n";
      action = "<cmd>Telescope lsp_code_actions<cr>";
      desc = "Code Action";
    }
    {
      key = "<leader>cr";
      mode = "n";
      lua = true;
      action = ''
        function()
          vim.lsp.buf.rename()
        end
      '';
      desc = "Rename";
    }
    {
      key = "<leader>cf";
      mode = "n";
      lua = true;
      action = ''
        function()
          vim.lsp.buf.format()
        end
      '';
      desc = "Format";
    }

    # Git
    {
      key = "<leader>gb";
      mode = "n";
      action = "<cmd>Telescope git_branches<cr>";
      silent = true;
      desc = "Branches";
    }
    {
      key = "<leader>gc";
      mode = "n";
      action = "<cmd>Telescope git_commits<cr>";
      silent = true;
      desc = "Repository Commits";
    }
    {
      key = "<leader>gC";
      mode = "n";
      action = "<cmd>Telescope git_bcommits<cr>";
      silent = true;
      desc = "Buffer Commits";
    }
    {
      key = "<leader>gs";
      mode = "n";
      action = "<cmd>Telescope git_status<cr>";
      silent = true;
      desc = "Status";
    }
    {
      key = "<leader>gS";
      mode = "n";
      action = "<cmd>Telescope git_stash<cr>";
      silent = true;
      desc = "Stashes";
    }
    {
      key = "<leader>gf";
      mode = "n";
      action = "<cmd>Telescope git_files<cr>";
      silent = true;
      desc = "Git Files";
    }

    # Jump
    {
      key = "<leader>jd";
      mode = "n";
      action = "<cmd>Telescope lsp_definitions<cr>";
      desc = "Definition";
    }
    {
      key = "<leader>jD";
      mode = "n";
      action = "<cmd>Telescope lsp_declarations<cr>";
      desc = "Declaration";
    }
    {
      key = "<leader>jr";
      mode = "n";
      action = "<cmd>Telescope lsp_references<cr>";
      desc = "References";
    }
    {
      key = "<leader>ji";
      mode = "n";
      action = "<cmd>Telescope lsp_implementations<cr>";
      desc = "Implementation";
    }
    {
      key = "<leader>jt";
      mode = "n";
      action = "<cmd>Telescope lsp_type_definitions<cr>";
      desc = "Type Definition";
    }

    # LSP
    {
      key = "<leader>lf";
      mode = "n";
      action = "<cmd>Lspsaga finder<cr>";
      desc = "Finder";
    }
    {
      key = "<leader>lw";
      mode = "n";
      action = "<cmd>Telescope lsp_document_symbols<cr>";
      desc = "Document Symbols";
    }
    {
      key = "<leader>lW";
      mode = "n";
      action = "<cmd>Telescope lsp_workspace_symbols<cr>";
      desc = "Workspace Symbols";
    }
    {
      key = "<leader>ll";
      mode = "n";
      action = "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>";
      desc = "Live Symbols";
    }
    {
      key = "<leader>li";
      mode = "n";
      action = "<cmd>Telescope lsp_incoming_calls<cr>";
      desc = "Incoming Calls";
    }
    {
      key = "<leader>lo";
      mode = "n";
      action = "<cmd>Telescope lsp_outgoing_calls<cr>";
      desc = "Outgoing Calls";
    }

    # Projects
    {
      key = "<leader>pp";
      mode = "n";
      lua = true;
      action = ''
        function()
          require("nvf.project_sessions").select_project()
        end
      '';
      desc = "Project Picker";
    }
    {
      key = "<leader>ps";
      mode = "n";
      lua = true;
      action = ''
        function()
          require("nvf.project_sessions").save()
        end
      '';
      desc = "Save Session";
    }
    {
      key = "<leader>pl";
      mode = "n";
      lua = true;
      action = ''
        function()
          require("nvf.project_sessions").load()
        end
      '';
      desc = "Load Session";
    }

    # Toggles
    {
      key = "<leader>th";
      mode = "n";
      lua = true;
      action = ''
        function()
          require("nvf.keymaps").toggle_inlay_hints()
        end
      '';
      desc = "Inlay Hints";
    }

    # Diagnostics
    {
      key = "<leader>xx";
      mode = "n";
      action = "<cmd>Trouble diagnostics toggle<cr>";
      desc = "Diagnostics";
    }
    {
      key = "<leader>xb";
      mode = "n";
      action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
      desc = "Buffer Diagnostics";
    }
    {
      key = "<leader>xs";
      mode = "n";
      action = "<cmd>Trouble symbols toggle focus=false<cr>";
      desc = "Symbols";
    }
    {
      key = "<leader>xl";
      mode = "n";
      action = "<cmd>Trouble lsp toggle focus=false win.position=right<cr>";
      desc = "LSP";
    }
    {
      key = "<leader>xq";
      mode = "n";
      action = "<cmd>Trouble qflist toggle<cr>";
      desc = "Quickfix";
    }
  ];
}
