local fun = require "fun"
-- TODO:
-- 1. use enhanced bd in fzf buffer list ctrl + x
-- 2. create utility commands on fzf like copy current file path
-- 3. add lazygit? or rely only on mini git
-- 4. move the copy diagnostic utility as loosely coupled in @utils.lua
-- 5. tidy up ripgrep plugin configuration
-- 6. document everything in @utils.lua

vim.cmd [[ colorscheme murphy ]]
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
vim.api.nvim_create_user_command("Normal", function()
  vim.notify("Macro execution disabled", vim.log.levels.WARN)
end, {})

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

  do
    require("mini.bufremove").setup()

    local U = require "utils"
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

  do
    require("mini.misc").setup()
    MiniMisc.setup_termbg_sync()
  end
end)

-- Configure oil.nvim for filesystem management and tree-walking utilities
-- The only feature bound to the keymap is the file explorer toggled by '-'
add {
  source = "stevearc/oil.nvim",
  checkout = "master",
}

do_now(function()
  require("oil").setup {
    default_file_explorer = true,
    watch_for_changes = true,
    float = {
      padding = 4,
      max_width = 0.5,
      max_height = 0.5,
      border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
    },
  }

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "oil",
    callback = function(ev)
      local function map(lhs)
        vim.keymap.set("n", lhs, function()
          -- only close if the current Oil window is a float
          local cfg = vim.api.nvim_win_get_config(0)
          if cfg and (cfg.relative or "") ~= "" then
            require("oil").close()
          else
          end
        end, { buffer = ev.buf, desc = "Close Oil float" })
      end
      map "q"
      map "<Esc>" -- normal-mode only; won’t eat Visual-mode <Esc>
    end,
  })

  vim.keymap.set("n", "-", "<cmd>Oil --float<CR>", { desc = "Open file explorer" })
end)

-- Configure treesitter for extended syntax support and textobject queries + semantic navigation
-- It is basically a core of every NeoVim configuration.
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

  require("mason-lspconfig").setup {
    ensure_installed = require("utils").mason_lspconfig(require "mason-lspconfig").server_to_lsp {
      "lua_ls",
      "vtsls",
      "biome",
      "stylua",
      "prettier",
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

  formatters_by_ft.lua = { "stylua" }

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
    fzf_colors = true,
    fzf_opts = {
      ["--scrollbar"] = "██",
    },
    previewers = {
      bat = {
        cmd = "bat",
        args = "--color=always --theme=murphy --style=changes",
      },
    },
    winopts = {
      height = 0.55,
      width = 1,
      row = 1,
      col = 0,
      backdrop = 50,
      border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
      preview = {
        border = "none",
        vertical = "down:45%,border-left",
        horizontal = "right:60%,border-left",
        winopts = {
          hidden = "hidden",
        },
      },
    },
  }

  local fzf_utils = require("utils").fzf_lua_utils(fzf)

  -- Pick dir(s) with fd, preview via `lstr`, then run your live ripgrep in them.

  local function _parse_diag_entry(entry)
    if type(entry) == "table" then
      -- when fzf-lua passes rich entries
      return entry.path or entry.filename, entry.lnum, entry.col, entry.severity, entry.code, entry.text
    end
    -- fallback: parse "file:lnum:col: rest"
    local file, l, c, rest = tostring(entry):match "^([^:]+):(%d+):(%d+):%s*(.*)$"
    return file, tonumber(l), tonumber(c), nil, nil, rest
  end

  local function copy_diagnostic(selected)
    local e = selected and selected[1]
    if not e then
      return
    end
    local file, lnum, col, severity, code, text = _parse_diag_entry(e)
    if not file then
      return
    end
    -- compose a nice, compact line
    local sev = severity and (tostring(severity):upper()) or nil
    local codepart = code and ("(" .. code .. ")") or nil
    local meta = vim.tbl_filter(function(s)
      return s and #s > 0
    end, { sev, codepart })
    local meta_str = #meta > 0 and (" " .. table.concat(meta, " ")) or ""
    local line = string.format("%s:%d:%d:%s%s", file, lnum or 1, col or 1, (text or ""):gsub("^%s+", ""), meta_str)

    vim.fn.setreg("+", line) -- system clipboard
    vim.fn.setreg('"', line) -- unnamed register (nice for `p`)
    vim.notify("Copied diagnostic:\n" .. line)
  end

  vim.keymap.set("n", "<leader>ld", function()
    fzf.diagnostics_document {
      actions = {
        ["ctrl-c"] = copy_diagnostic,
      },
      fzf_opts = { ["--preview-window"] = "right:60%:wrap:+{2}" },
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
