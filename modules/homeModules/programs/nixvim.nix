{inputs, ...}: {
  flake.homeModules.nixvim = {...}: {
    imports = [
      inputs.nixvim.homeModules.nixvim
    ];

    programs.nixvim = {pkgs, ...}: {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      globals = {
        mapleader = " ";
        maplocalleader = "\\";
        autoformat = true;
      };

      opts = {
        autowrite = true;
        clipboard = "unnamedplus";
        cmdheight = 1;
        completeopt = [
          "menu"
          "menuone"
          "noselect"
        ];
        conceallevel = 2;
        confirm = true;
        cursorline = true;
        expandtab = true;
        foldlevel = 99;
        foldmethod = "indent";
        grepformat = "%f:%l:%c:%m";
        grepprg = "rg --vimgrep";
        ignorecase = true;
        inccommand = "nosplit";
        laststatus = 3;
        linebreak = true;
        list = true;
        mouse = "a";
        number = true;
        pumblend = 10;
        pumheight = 10;
        relativenumber = true;
        ruler = false;
        scrolloff = 4;
        shiftround = true;
        shiftwidth = 2;
        showmode = false;
        sidescrolloff = 8;
        signcolumn = "yes";
        smartcase = true;
        smartindent = true;
        smoothscroll = true;
        spelllang = ["en"];
        splitbelow = true;
        splitkeep = "screen";
        splitright = true;
        tabstop = 2;
        termguicolors = true;
        timeoutlen = 300;
        undofile = true;
        undolevels = 10000;
        updatetime = 200;
        virtualedit = "block";
        wildmode = "longest:full,full";
        winminwidth = 5;
        wrap = false;
      };

      extraPackages = with pkgs; [
        alejandra
        biome
        deadnix
        git
        lazygit
        markdownlint-cli
        neovim-remote
        prettier
        shfmt
        shellcheck
        statix
        stylua
        taplo
        tmux
        yamllint
      ];

      diagnostic.settings = {
        signs = true;
        severity_sort = true;
        underline = true;
        update_in_insert = false;
        virtual_text = true;
      };

      autoGroups.lazyvim_general.clear = true;

      autoCmd = [
        {
          event = [
            "FocusGained"
            "TermClose"
            "TermLeave"
          ];
          group = "lazyvim_general";
          command = "checktime";
          desc = "Check if file changed outside Neovim";
        }
        {
          event = "TextYankPost";
          group = "lazyvim_general";
          desc = "Highlight yank";
          callback.__raw = ''
            function()
              vim.highlight.on_yank()
            end
          '';
        }
        {
          event = "VimResized";
          group = "lazyvim_general";
          command = "tabdo wincmd =";
          desc = "Resize splits on window resize";
        }
        {
          event = "BufReadPost";
          group = "lazyvim_general";
          desc = "Restore cursor position";
          callback.__raw = ''
            function(event)
              local exclude = { "gitcommit" }
              local buf = event.buf
              if vim.tbl_contains(exclude, vim.bo[buf].filetype) then
                return
              end
              local mark = vim.api.nvim_buf_get_mark(buf, '"')
              local line_count = vim.api.nvim_buf_line_count(buf)
              if mark[1] > 0 and mark[1] <= line_count then
                pcall(vim.api.nvim_win_set_cursor, 0, mark)
              end
            end
          '';
        }
        {
          event = "FileType";
          group = "lazyvim_general";
          pattern = [
            "PlenaryTestPopup"
            "checkhealth"
            "grug-far"
            "help"
            "lspinfo"
            "man"
            "notify"
            "qf"
            "query"
            "startuptime"
            "tsplayground"
          ];
          desc = "Close utility buffers with q";
          callback.__raw = ''
            function(event)
              vim.bo[event.buf].buflisted = false
              vim.keymap.set("n", "q", "<cmd>close<cr>", {
                buffer = event.buf,
                silent = true,
                desc = "Quit buffer",
              })
            end
          '';
        }
        {
          event = "FileType";
          group = "lazyvim_general";
          pattern = [
            "gitcommit"
            "markdown"
            "plaintex"
            "text"
            "typst"
          ];
          desc = "Enable wrap and spell for text";
          callback.__raw = ''
            function()
              vim.opt_local.wrap = true
              vim.opt_local.spell = true
            end
          '';
        }
        {
          event = "FileType";
          group = "lazyvim_general";
          pattern = [
            "json"
            "jsonc"
            "json5"
          ];
          desc = "Disable JSON conceal";
          callback.__raw = ''
            function()
              vim.opt_local.conceallevel = 0
            end
          '';
        }
        {
          event = "BufWritePre";
          group = "lazyvim_general";
          desc = "Create parent directories on save";
          callback.__raw = ''
            function(event)
              if event.match:match("^%w%w+://") then
                return
              end
              local file = vim.uv.fs_realpath(event.match) or event.match
              vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
            end
          '';
        }
        {
          event = [
            "DirChanged"
            "VimEnter"
          ];
          group = "lazyvim_general";
          desc = "Set tmux title from cwd";
          callback.__raw = ''
            function()
              if not vim.env.TMUX then
                return
              end

              local cwd = vim.uv.cwd() or vim.fn.getcwd()
              local home = vim.env.HOME or ""
              if home ~= "" and cwd:sub(1, #home) == home then
                cwd = "~" .. cwd:sub(#home + 1)
              end

              local parts = {}
              for part in cwd:gmatch("[^/]+") do
                table.insert(parts, part)
              end

              local title = cwd
              if #parts >= 2 then
                title = parts[#parts - 1] .. "/" .. parts[#parts]
              elseif #parts == 1 then
                title = parts[1]
              end
              title = " " .. title

              vim.g.__nixvim_tmux_title = title
              if vim.g.__nixvim_tmux_original_window == nil then
                local original = vim.fn.system({ "tmux", "display-message", "-p", "#W" })
                vim.g.__nixvim_tmux_original_window = vim.trim(original)
              end

              vim.fn.system({ "tmux", "select-pane", "-T", title })
              vim.fn.system({ "tmux", "rename-window", title })
            end
          '';
        }
        {
          event = "VimLeavePre";
          group = "lazyvim_general";
          desc = "Restore tmux title";
          callback.__raw = ''
            function()
              if not vim.env.TMUX then
                return
              end

              vim.fn.system({ "tmux", "select-pane", "-T", "" })

              local original = vim.g.__nixvim_tmux_original_window
              local title = vim.g.__nixvim_tmux_title
              if original == nil or original == "" then
                return
              end

              local current = vim.trim(vim.fn.system({ "tmux", "display-message", "-p", "#W" }))
              if title == nil or current == title then
                vim.fn.system({ "tmux", "rename-window", original })
              end
            end
          '';
        }
      ];

      colorscheme = "catppuccin";

      colorschemes = {
        catppuccin = {
          enable = true;
          settings = {
            flavour = "mocha";
            term_colors = true;
            styles = {
              comments = ["italic"];
              conditionals = ["italic"];
              keywords = ["italic"];
            };
          };
        };
      };

      plugins = {
        blink-cmp = {
          enable = true;
          setupLspCapabilities = true;
          settings = {
            completion.documentation.auto_show = true;
            keymap.preset = "super-tab";
            signature.enabled = true;
            sources.default = [
              "lsp"
              "path"
              "snippets"
              "buffer"
            ];
          };
        };

        bufferline = {
          enable = true;
          settings.options = {
            always_show_bufferline = false;
            close_command.__raw = ''
              function(bufnum)
                require("mini.bufremove").delete(bufnum, false)
              end
            '';
            diagnostics = "nvim_lsp";
            right_mouse_command.__raw = ''
              function(bufnum)
                require("mini.bufremove").delete(bufnum, false)
              end
            '';
            offsets = [
              {
                filetype = "neo-tree";
                highlight = "Directory";
                text = "Neo-tree";
                text_align = "left";
              }
            ];
          };
        };

        flash.enable = true;

        gitsigns = {
          enable = true;
          settings = {
            current_line_blame = false;
            signs = {
              add.text = "▎";
              change.text = "▎";
              changedelete.text = "▎";
              delete.text = "";
              topdelete.text = "";
              untracked.text = "▎";
            };
          };
        };

        conform-nvim = {
          enable = true;
          settings = {
            default_format_opts = {
              async = false;
              lsp_format = "fallback";
              quiet = false;
              timeout_ms = 3000;
            };
            format_on_save = {
              lsp_format = "fallback";
              timeout_ms = 1000;
            };
            formatters_by_ft = {
              bash = ["shfmt"];
              css = ["prettier"];
              html = ["prettier"];
              javascript = ["prettier"];
              javascriptreact = ["prettier"];
              json = ["prettier"];
              lua = ["stylua"];
              markdown = ["prettier"];
              nix = ["alejandra"];
              sh = ["shfmt"];
              toml = ["taplo"];
              typescript = ["prettier"];
              typescriptreact = ["prettier"];
              yaml = ["prettier"];
            };
          };
        };

        indent-blankline = {
          enable = true;
          settings = {
            indent.char = "│";
            scope.enabled = true;
          };
        };

        lualine = {
          enable = true;
          settings.options = {
            globalstatus = true;
            theme = "auto";
            component_separators = {
              left = "";
              right = "";
            };
            section_separators = {
              left = "";
              right = "";
            };
          };
        };

        lazydev = {
          enable = true;
          settings.integrations = {
            cmp = false;
            lspconfig = true;
          };
        };

        lazygit = {
          enable = true;
          settings = {
            floating_window_scaling_factor = 0.9;
            floating_window_winblend = 0;
            use_neovim_remote = 1;
          };
        };

        lint = {
          enable = true;
          lintersByFt = {
            bash = ["shellcheck"];
            javascript = ["biomejs"];
            javascriptreact = ["biomejs"];
            markdown = ["markdownlint"];
            nix = [
              "statix"
              "deadnix"
            ];
            sh = ["shellcheck"];
            typescript = ["biomejs"];
            typescriptreact = ["biomejs"];
            yaml = ["yamllint"];
          };
        };

        lsp = {
          enable = true;
          inlayHints = true;
          keymaps = {
            silent = true;
            diagnostic = {
              "[d" = "goto_prev";
              "]d" = "goto_next";
            };
            lspBuf = {
              "<leader>ca" = "code_action";
              "<leader>cr" = "rename";
              "gD" = "declaration";
              "gI" = "implementation";
              "gd" = "definition";
              "gr" = "references";
              "gy" = "type_definition";
              "K" = "hover";
            };
          };
          servers = {
            bashls.enable = true;
            cssls.enable = true;
            html.enable = true;
            jsonls.enable = true;
            lua_ls = {
              enable = true;
              settings.Lua = {
                completion.callSnippet = "Replace";
                diagnostics.globals = ["vim"];
                telemetry.enable = false;
                workspace.checkThirdParty = false;
              };
            };
            marksman.enable = true;
            nil_ls = {
              enable = true;
              settings.nil.formatting.command = ["alejandra"];
            };
            taplo.enable = true;
            ts_ls.enable = true;
            yamlls.enable = true;
          };
        };

        mini = {
          enable = true;
          modules = {
            ai.n_lines = 500;
            bufremove = {};
            pairs = {};
          };
        };

        neo-tree = {
          enable = true;
          settings = {
            close_if_last_window = true;
            filesystem = {
              follow_current_file.enabled = true;
              use_libuv_file_watcher = true;
            };
          };
        };

        noice = {
          enable = true;
          settings = {
            cmdline = {
              enabled = true;
              view = "cmdline";
            };
            lsp.progress.enabled = true;
            messages.enabled = true;
            notify.enabled = true;
            presets = {
              bottom_search = true;
              command_palette = false;
              lsp_doc_border = true;
              long_message_to_split = true;
            };
          };
        };

        notify = {
          enable = true;
          settings = {
            background_colour = "#000000";
            stages = "fade_in_slide_out";
            timeout = 3000;
          };
        };

        persistence.enable = true;

        telescope = {
          enable = true;
          settings.defaults = {
            prompt_prefix = " ";
            selection_caret = " ";
          };
        };

        todo-comments.enable = true;

        toggleterm = {
          enable = true;
          settings = {
            direction = "float";
            float_opts = {
              border = "curved";
              height = 30;
              width = 130;
            };
            open_mapping = ''[[<c-\>]]'';
            persist_mode = true;
            shade_terminals = true;
          };
        };

        treesitter = {
          enable = true;
          folding.enable = false;
          grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
            bash
            c
            diff
            html
            javascript
            jsdoc
            json
            lua
            luadoc
            luap
            markdown
            markdown_inline
            nix
            printf
            python
            query
            regex
            toml
            tsx
            typescript
            vim
            vimdoc
            xml
            yaml
          ];
          highlight.enable = true;
          indent.enable = true;
        };

        treesitter-textobjects.enable = true;

        trouble.enable = true;

        ts-autotag = {
          enable = true;
          settings.opts = {
            enable_close = true;
            enable_close_on_slash = true;
            enable_rename = true;
          };
        };

        web-devicons.enable = true;

        which-key = {
          enable = true;
          settings = {
            delay = 200;
            preset = "modern";
          };
        };
      };

      keymaps = [
        {
          mode = [
            "n"
            "x"
          ];
          key = "j";
          action = "v:count == 0 ? 'gj' : 'j'";
          options = {
            desc = "Down";
            expr = true;
            silent = true;
          };
        }
        {
          mode = [
            "n"
            "x"
          ];
          key = "k";
          action = "v:count == 0 ? 'gk' : 'k'";
          options = {
            desc = "Up";
            expr = true;
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<C-h>";
          action = "<C-w>h";
          options.desc = "Go to Left Window";
        }
        {
          mode = "n";
          key = "<C-j>";
          action = "<C-w>j";
          options.desc = "Go to Lower Window";
        }
        {
          mode = "n";
          key = "<C-k>";
          action = "<C-w>k";
          options.desc = "Go to Upper Window";
        }
        {
          mode = "n";
          key = "<C-l>";
          action = "<C-w>l";
          options.desc = "Go to Right Window";
        }
        {
          mode = "n";
          key = "<C-Up>";
          action = "<cmd>resize +2<cr>";
          options.desc = "Increase Window Height";
        }
        {
          mode = "n";
          key = "<C-Down>";
          action = "<cmd>resize -2<cr>";
          options.desc = "Decrease Window Height";
        }
        {
          mode = "n";
          key = "<C-Left>";
          action = "<cmd>vertical resize -2<cr>";
          options.desc = "Decrease Window Width";
        }
        {
          mode = "n";
          key = "<C-Right>";
          action = "<cmd>vertical resize +2<cr>";
          options.desc = "Increase Window Width";
        }
        {
          mode = "n";
          key = "<A-j>";
          action = "<cmd>move .+1<cr>==";
          options.desc = "Move Down";
        }
        {
          mode = "n";
          key = "<A-k>";
          action = "<cmd>move .-2<cr>==";
          options.desc = "Move Up";
        }
        {
          mode = "i";
          key = "<A-j>";
          action = "<esc><cmd>move .+1<cr>==gi";
          options.desc = "Move Down";
        }
        {
          mode = "i";
          key = "<A-k>";
          action = "<esc><cmd>move .-2<cr>==gi";
          options.desc = "Move Up";
        }
        {
          mode = "v";
          key = "<A-j>";
          action = ":move '>+1<cr>gv=gv";
          options.desc = "Move Down";
        }
        {
          mode = "v";
          key = "<A-k>";
          action = ":move '<-2<cr>gv=gv";
          options.desc = "Move Up";
        }
        {
          mode = "n";
          key = "<S-h>";
          action = "<cmd>bprevious<cr>";
          options.desc = "Prev Buffer";
        }
        {
          mode = "n";
          key = "<S-l>";
          action = "<cmd>bnext<cr>";
          options.desc = "Next Buffer";
        }
        {
          mode = "n";
          key = "[b";
          action = "<cmd>bprevious<cr>";
          options.desc = "Prev Buffer";
        }
        {
          mode = "n";
          key = "]b";
          action = "<cmd>bnext<cr>";
          options.desc = "Next Buffer";
        }
        {
          mode = "n";
          key = "<leader>bb";
          action = "<cmd>buffer #<cr>";
          options.desc = "Switch to Other Buffer";
        }
        {
          mode = "n";
          key = "<leader>`";
          action = "<cmd>buffer #<cr>";
          options.desc = "Switch to Other Buffer";
        }
        {
          mode = "n";
          key = "<leader>bd";
          action = "<cmd>bdelete<cr>";
          options.desc = "Delete Buffer";
        }
        {
          mode = "n";
          key = "<leader>bD";
          action = "<cmd>bdelete!<cr>";
          options.desc = "Delete Buffer (Force)";
        }
        {
          mode = [
            "i"
            "n"
            "s"
          ];
          key = "<esc>";
          action = "<cmd>noh<cr><esc>";
          options.desc = "Escape and Clear Search";
        }
        {
          mode = [
            "n"
            "x"
          ];
          key = "<C-s>";
          action = "<cmd>write<cr><esc>";
          options.desc = "Save File";
        }
        {
          mode = "i";
          key = "<C-s>";
          action = "<esc><cmd>write<cr>";
          options.desc = "Save File";
        }
        {
          mode = "x";
          key = "<";
          action = "<gv";
          options.desc = "Indent Left";
        }
        {
          mode = "x";
          key = ">";
          action = ">gv";
          options.desc = "Indent Right";
        }
        {
          mode = "n";
          key = "<leader>fn";
          action = "<cmd>enew<cr>";
          options.desc = "New File";
        }
        {
          mode = "n";
          key = "<leader><space>";
          action = "<cmd>Telescope find_files<cr>";
          options.desc = "Find Files (Root Dir)";
        }
        {
          mode = "n";
          key = "<leader>,";
          action = "<cmd>Telescope buffers show_all_buffers=true<cr>";
          options.desc = "Buffers";
        }
        {
          mode = "n";
          key = "<leader>/";
          action = "<cmd>Telescope live_grep<cr>";
          options.desc = "Grep (Root Dir)";
        }
        {
          mode = "n";
          key = "<leader>:";
          action = "<cmd>Telescope command_history<cr>";
          options.desc = "Command History";
        }
        {
          mode = "n";
          key = "<leader>fb";
          action = "<cmd>Telescope buffers<cr>";
          options.desc = "Buffers";
        }
        {
          mode = "n";
          key = "<leader>fB";
          action = "<cmd>Telescope buffers show_all_buffers=true<cr>";
          options.desc = "Buffers (All)";
        }
        {
          mode = "n";
          key = "<leader>ff";
          action = "<cmd>Telescope find_files<cr>";
          options.desc = "Find Files (Root Dir)";
        }
        {
          mode = "n";
          key = "<leader>fF";
          action = "<cmd>Telescope find_files cwd=.<cr>";
          options.desc = "Find Files (cwd)";
        }
        {
          mode = "n";
          key = "<leader>fg";
          action = "<cmd>Telescope git_files<cr>";
          options.desc = "Find Files (git-files)";
        }
        {
          mode = "n";
          key = "<leader>fr";
          action = "<cmd>Telescope oldfiles<cr>";
          options.desc = "Recent";
        }
        {
          mode = "n";
          key = "<leader>e";
          action = "<cmd>Neotree toggle reveal<cr>";
          options.desc = "Explorer Neo-tree";
        }
        {
          mode = "n";
          key = "<leader>E";
          action = "<cmd>Neotree toggle dir=.<cr>";
          options.desc = "Explorer Neo-tree (cwd)";
        }
        {
          mode = "n";
          key = "<leader>xx";
          action = "<cmd>Trouble diagnostics toggle<cr>";
          options.desc = "Diagnostics (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>xX";
          action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
          options.desc = "Buffer Diagnostics (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>cs";
          action = "<cmd>Trouble symbols toggle focus=false<cr>";
          options.desc = "Symbols (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>cl";
          action = "<cmd>Trouble lsp toggle focus=false win.position=right<cr>";
          options.desc = "LSP Definitions / references (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>xL";
          action = "<cmd>Trouble loclist toggle<cr>";
          options.desc = "Location List (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>xQ";
          action = "<cmd>Trouble qflist toggle<cr>";
          options.desc = "Quickfix List (Trouble)";
        }
        {
          mode = "n";
          key = "]t";
          action = "<cmd>lua require('todo-comments').jump_next()<cr>";
          options.desc = "Next Todo Comment";
        }
        {
          mode = "n";
          key = "[t";
          action = "<cmd>lua require('todo-comments').jump_prev()<cr>";
          options.desc = "Previous Todo Comment";
        }
        {
          mode = "n";
          key = "<leader>xt";
          action = "<cmd>Trouble todo toggle<cr>";
          options.desc = "Todo (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>st";
          action = "<cmd>TodoTelescope<cr>";
          options.desc = "Todo";
        }
        {
          mode = "n";
          key = "<leader>gg";
          action = "<cmd>LazyGit<cr>";
          options.desc = "Lazygit";
        }
        {
          mode = "n";
          key = "<leader>gG";
          action = "<cmd>LazyGit<cr>";
          options.desc = "Lazygit (cwd)";
        }
        {
          mode = "n";
          key = "<leader>gb";
          action = "<cmd>Gitsigns blame_line<cr>";
          options.desc = "Git Blame Line";
        }
        {
          mode = "n";
          key = "<leader>gB";
          action = "<cmd>Gitsigns toggle_current_line_blame<cr>";
          options.desc = "Toggle Git Blame Line";
        }
        {
          mode = "n";
          key = "<leader>gh";
          action = "<cmd>Gitsigns preview_hunk<cr>";
          options.desc = "Preview Hunk";
        }
        {
          mode = [
            "n"
            "t"
          ];
          key = "<C-/>";
          action = "<cmd>ToggleTerm<cr>";
          options.desc = "Terminal (Root Dir)";
        }
        {
          mode = [
            "n"
            "t"
          ];
          key = "<C-_>";
          action = "<cmd>ToggleTerm<cr>";
          options.desc = "which_key_ignore";
        }
        {
          mode = "n";
          key = "<leader>ft";
          action = "<cmd>ToggleTerm direction=float<cr>";
          options.desc = "Terminal (Root Dir)";
        }
        {
          mode = "n";
          key = "<leader>fT";
          action = "<cmd>ToggleTerm direction=float dir=.<cr>";
          options.desc = "Terminal (cwd)";
        }
        {
          mode = "n";
          key = "<leader>qq";
          action = "<cmd>quitall<cr>";
          options.desc = "Quit All";
        }
        {
          mode = "n";
          key = "<leader>-";
          action = "<C-W>s";
          options.desc = "Split Window Below";
        }
        {
          mode = "n";
          key = "<leader>|";
          action = "<C-W>v";
          options.desc = "Split Window Right";
        }
        {
          mode = "n";
          key = "<leader>wd";
          action = "<C-W>c";
          options.desc = "Delete Window";
        }
        {
          mode = "n";
          key = "<leader><tab><tab>";
          action = "<cmd>tabnew<cr>";
          options.desc = "New Tab";
        }
        {
          mode = "n";
          key = "<leader><tab>]";
          action = "<cmd>tabnext<cr>";
          options.desc = "Next Tab";
        }
        {
          mode = "n";
          key = "<leader><tab>[";
          action = "<cmd>tabprevious<cr>";
          options.desc = "Previous Tab";
        }
        {
          mode = "n";
          key = "<leader><tab>d";
          action = "<cmd>tabclose<cr>";
          options.desc = "Close Tab";
        }
        {
          mode = "n";
          key = "<leader><tab>o";
          action = "<cmd>tabonly<cr>";
          options.desc = "Close Other Tabs";
        }
      ];
    };
  };
}
