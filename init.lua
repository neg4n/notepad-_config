local fun = require "fun"
local U = require "utils"

U.helpers.macos_detect_system_theme.setup {
  colorscheme = { light = "peachpuff", dark = "murphy" },
  poll_interval_ms = 10000,
  on_change = function(_, is_dark, _)
    vim.env.BAT_THEME = is_dark and "murphy" or "peachpuff"
  end,
}

if vim.g.colors_name == nil then
  vim.cmd.colorscheme "murphy"
end

vim.g.mapleader = " "
vim.opt.termguicolors = true
vim.opt.ttyfast = true
vim.opt.relativenumber = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv "HOME" .. "/.vim/undodir"
vim.opt.undofile = true
vim.opt.smartindent = true
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- Disable macro recording and playback in Neovim
vim.keymap.set({ "n", "x" }, "q", "<nop>", { desc = "Disable macro recording" })
vim.keymap.set({ "n", "x" }, "@", "<nop>", { desc = "Disable macro playback" })
vim.keymap.set({ "n", "x" }, "Q", "<nop>", { desc = "Disable Ex-mode (legacy)" })
vim.api.nvim_set_keymap("n", "@@", "<nop>", { noremap = true, silent = true })

-- Setup blackhole register for sequential replaces without yanks (Helix Editor like experience)
U.blackhole.setup {
  exclude_filetypes = { "grug-far", "grug-far-history", "grug-far-help" },
  exclude_buftypes = { "help", "nofile", "prompt", "terminal" },
  modes = { "n", "x" },
  keys = { "c", "C", "s", "S", "x", "X" },
}

-- Clone 'mini.nvim' manually in a way that it gets managed by 'mini.deps'
local path_package = vim.fn.stdpath "data" .. "/site/"
local mini_path = path_package .. "pack/deps/start/mini.nvim"
if not vim.loop.fs_stat(mini_path) then
  vim.cmd 'echo "Installing `mini.nvim`" | redraw'
  local clone_cmd = {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/nvim-mini/mini.nvim",
    mini_path,
  }
  vim.fn.system(clone_cmd)
  vim.cmd "packadd mini.nvim | helptags ALL"
  vim.cmd 'echo "Installed `mini.nvim`" | redraw'
end

-- Configure mini.deps helpers for configuring the plugins
require("mini.deps").setup { path = { package = path_package } }
local add, do_now, do_later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- Configure mini.nvim very important built-ins immediately, the mini.nvim itself is already installed along
-- with the package manager (mini.deps) and these packages are required as soon as possible.
do_now(function()
  do
    require("mini.misc").setup()
    MiniMisc.setup_termbg_sync()
  end
  -- Configure mini.nvim for filesystem management and tree-walking utilities
  -- (the goal is to somewhat resemble the oil.nvim experience and keybindings)
  -- The only feature bound to the keymap is the file explorer toggled by '-'
  do
    require("mini.files").setup()

    local write_override_undo
    local active_explorers = 0
    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniFilesBufferCreate",
      callback = function(args)
        local buf_id = args.data.buf_id
        local function map(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = desc })
        end
        map("-", function()
          MiniFiles.go_out()
        end, "MiniFiles go out")
        map("<CR>", function()
          MiniFiles.go_in()
        end, "MiniFiles go in")
      end,
    })

    local overcmd = U.overcmd

    local function ensure_write_override()
      if write_override_undo then
        return
      end
      write_override_undo = overcmd.override {
        from = "write",
        canon = "MiniFilesWrite",
        handler = function(o)
          if vim.bo[vim.api.nvim_get_current_buf()].filetype == "minifiles" then
            local ok, err = pcall(MiniFiles.synchronize)
            if not ok then
              vim.notify(("MiniFiles synchronize failed: %s"):format(err), vim.log.levels.ERROR)
            end
            return
          end

          local cmd_opts = {
            cmd = "write",
            bang = o.bang,
            mods = o.mods,
            args = vim.deepcopy(o.fargs),
          }
          if o.range and o.range > 0 then
            cmd_opts.range = o.range
            cmd_opts.line1 = o.line1
            cmd_opts.line2 = o.line2
          end
          vim.api.nvim_cmd(cmd_opts, {})
        end,
        usercmd = {
          bang = true,
          nargs = "*",
          range = true,
          complete = "file",
          bar = true,
          desc = "Proxy :write to MiniFiles.synchronize when explorer buffer",
        },
        min_prefix_len = 1,
      }
    end

    local function teardown_write_override()
      if not write_override_undo then
        return
      end
      write_override_undo()
      write_override_undo = nil
    end

    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniFilesExplorerOpen",
      callback = function()
        active_explorers = active_explorers + 1
        if active_explorers == 1 then
          ensure_write_override()
        end
      end,
    })

    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniFilesExplorerClose",
      callback = function()
        active_explorers = math.max(active_explorers - 1, 0)
        if active_explorers == 0 then
          teardown_write_override()
        end
      end,
    })

    vim.keymap.set("n", "-", function()
      MiniFiles.open(vim.api.nvim_buf_get_name(0), false)
    end, { desc = "Open file explorer" })
  end
  do
    require("mini.notify").setup()
    vim.keymap.set("n", "<leader>n", function()
      MiniNotify.show_history()
    end, { desc = "Show notifications history" })
  end

  do
    require("mini.statusline").setup { use_icons = false }
  end
end)

-- Configure mini.nvim less important built-ins later, the mini.nvim itself is already installed along
-- with the package manager (mini.deps) and these packages are not required as soon as possible.
do_later(function()
  require("mini.pairs").setup()
  require("mini.git").setup()
  require("mini.surround").setup()
  require("mini.indentscope").setup()
  require("mini.cursorword").setup { delay = 500 }

  do
    local mini_jump2d = require "mini.jump2d"
    local nonblank_start = mini_jump2d.gen_spotter.pattern("%S+", "start")
    local alphanum_before_punct = mini_jump2d.gen_spotter.pattern("[^%s%p]%p", "start")
    local alphanum_after_punct = mini_jump2d.gen_spotter.pattern("%p[^%s%p]", "end")
    local upper_start = mini_jump2d.gen_spotter.pattern("%u+", "start")
    mini_jump2d.setup {
      -- Reuse default components but drop the end-of-word spot to avoid jumping to trailing letters.
      spotter = mini_jump2d.gen_spotter.union(nonblank_start, alphanum_before_punct, alphanum_after_punct, upper_start),
      mappings = {
        start_jumping = "gw",
      },
    }
    vim.api.nvim_set_hl(0, "MiniJump2dSpot", { reverse = true })
  end

  do
    require("mini.bufremove").setup()

    local overcmd = U.overcmd

    overcmd.override {
      from = { "bdelete", "bd" },
      canon = "Bdelete",
      handler = function(o)
        local buf = U.buffer.resolve(o.fargs[1])
        local ok = MiniBufremove.delete(buf, o.bang or false)
        if ok then
          vim.notify "Deleted current buffer"
        end
      end,
      usercmd = {
        bang = true,
        nargs = "?",
        complete = "buffer",
        desc = "Delete buffer via mini.bufremove",
      },
      min_prefix_len = 2,
      enter_fallback = true,
    }
  end
end)

-- Configure treesitter for extended syntax support and textobject queries + semantic navigation
-- It is basically a core of every NeoVim configuration.
vim.g.skip_treesitter = vim.g.skip_treesitter or false
if not vim.g.skip_treesitter then
  add {
    source = "nvim-treesitter/nvim-treesitter",
    checkout = "master",
    hooks = {
      post_checkout = function()
        vim.cmd [[ :TSUpdate ]]
      end,
    },
  }

  do_now(function()
      -- stylua: ignore
      local language_grammars = {
          "astro", "javascript", "typescript", "tsx", "css", "html", "scss",
          "cmake", "cpp", "c",
          "lua", "bash", "xml", "markdown",
      }
    require("nvim-treesitter.configs").setup {
      ensure_installed = language_grammars,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { "markdown" },
      },
    }
  end)
end

-- Configure LSP capabilities for the editing. Includes auto install of the language servers,
-- wiring them to the vim.lsp API and registering their capabilities into the autocomplete engine (blink.cmp)
add {
  source = "saghen/blink.cmp",
  depends = {
    { source = "mason-org/mason.nvim", checkout = "v2.1.0" },
    { source = "mason-org/mason-lspconfig.nvim", checkout = "v2.1.0" },
    { source = "neovim/nvim-lspconfig", checkout = "v2.1.0" },
  },
  checkout = "v1.7.0",
}

do_now(function()
  require("mason").setup()
  require("blink.cmp").setup {
    sources = {
      default = { "lsp", "path" },
    },
    keymap = { preset = "enter", ["<CR>"] = { "select_and_accept", "fallback" } },
  }

  local builtin = vim.lsp.protocol.make_client_capabilities()
  local blink = require("blink.cmp").get_lsp_capabilities({}, false)
  local caps = vim.tbl_deep_extend("force", builtin, blink)

  vim.lsp.config("tailwindcss", {
    filetypes = {
      "typescriptreact",
      "javascriptreact",
      "javascript",
      "html",
      "css",
      "hbs",
      "templ",
      "ejs",
    },
  })

  require("mason-lspconfig").setup {
    ensure_installed = U.mason_lspconfig(require "mason-lspconfig").server_to_lsp {
      "lua_ls",
      "vtsls",
      "biome",
      "stylua",
      "clangd",
      "prettier",
      "rust-analyzer",
      "tailwindcss-language-server",
    },
    automatic_enable = true,
  }

  vim.lsp.config("*", { capabilities = caps })

  vim.keymap.set("n", "gd", function()
    vim.lsp.buf.definition()
  end, { desc = "Go to definition" })
  -- grn = vim.lsp.buf.rename()
  -- gra = vim.lsp.buf.code_action()
end)

add {
  source = "MagicDuck/grug-far.nvim",
  checkout = "main",
}

do_now(function()
  local grug_far = require "grug-far"
  grug_far.setup {
    helpLine = {
      enabled = false,
    },
    showCompactInputs = false,
    showInputsTopPadding = true,
    showInputsBottomPadding = true,
  }

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("grug-far-keybindings", { clear = true }),
    pattern = { "grug-far" },
    callback = function()
      vim.keymap.set("n", "<C-a>", function()
        local inst = require("grug-far").get_instance(0)
        inst:replace()
      end, { buffer = true })
    end,
  })

  vim.keymap.set("n", "gsrc", function()
    grug_far.open { transient = true, prefills = { search = vim.fn.expand "%" } }
  end, { desc = "Search & Replace in current file" })

  vim.keymap.set("n", "gsr", function()
    grug_far.open { transient = true }
  end, { desc = "Search & Replace globally" })
end)

-- Configure formatting capabilities inside the NeoVim using external utilities
-- and the bridge that allows to make the process developer-friendly.
add {
  source = "stevearc/conform.nvim",
  checkout = "master",
}

do_now(function()
  local conform = require "conform"

  local formatters_by_ft = fun
    .iter({ "javascript", "typescript", "javascriptreact", "typescriptreact" })
    :map(function(ft)
      return ft,
        conform.get_formatter_info("biome").available and { "biome" } or {
          "prettierd",
          "prettier",
          stop_after_first = true,
        }
    end)
    :foldl(function(acc, k, v)
      acc[k] = v
      return acc
    end, {})

  conform.formatters.clang_format = {
    prepend_args = { "--style=file", "--fallback-style=LLVM" },
  }

  formatters_by_ft.lua = { "stylua" }
  formatters_by_ft.c = { "clang_format" }

  conform.setup {
    formatters_by_ft = formatters_by_ft,
  }

  vim.keymap.set("n", "<leader>r", function()
    conform.format({ async = true }, function(_, did_edit)
      if did_edit then
        vim.notify "Successfully formated"
      end
    end)
  end, { desc = "Format current buffer asynchronously" })
end)

-- Configure pickers
add {
  source = "ibhagwan/fzf-lua",
  checkout = "main",
}

do_now(function()
  local fzf = require "fzf-lua"

  fzf.setup {
    "max-perf",
    file_icons = false,
    files = { no_header_i = true },
    fzf_colors = true,
    fzf_opts = {
      ["--scrollbar"] = "██",
    },
    previewers = {
      bat = {
        cmd = "bat",
        args = "--color=always --theme=${BAT_THEME} --style=changes",
      },
    },
    winopts = {
      height = 0.90,
      width = 0.95,
      row = 1,
      col = 0.5,
      backdrop = 50,
      border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
      preview = {
        border = "none",
        vertical = "down:60%,border-top",
        horizontal = "down:60%,border-top",
        winopts = {
          hidden = "hidden",
        },
      },
    },
  }

  local fzf_utils = U.fzf_lua_utils(fzf)

  vim.keymap.set("n", "<leader>ld", function()
    fzf.diagnostics_document {
      actions = {
        ["y"] = fzf_utils.copy_diagnostic,
      },
      fzf_opts = { ["--preview-window"] = "right:60%:wrap:+{2}", ["--header"] = ":: y to yank the diagnostic" },
    }
  end, { desc = "Document diagnostics (fzf-lua) with copy" })

  vim.keymap.set("n", "<leader>f", fzf.files, { desc = "Find files" })
  vim.keymap.set("n", "<leader>s", fzf.lsp_document_symbols, { desc = "Symbols" })
  vim.keymap.set("n", "<leader>b", fzf.buffers, { desc = "Navigate through open buffers" })
  vim.keymap.set("n", "<leader>/", fzf_utils.live_ripgrep, { desc = "Live grep" })
  vim.keymap.set("n", "<leader>?", fzf_utils.pick_dirs_then_live_ripgrep, { desc = "Pick dirs then live ripgrep" })

  vim.keymap.set("n", "<leader>g", fzf.git_diff, { desc = "Git files" })
  vim.keymap.set("n", "<leader>vh", fzf.help_tags, { desc = "Help tags" })
end)
