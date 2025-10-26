local fun = require "fun"
local uv = assert(vim.uv, "Neovim 0.11+ with vim.uv support is required")
local fs = assert(vim.fs, "vim.fs API is required")

local U = {}

U.buffer = (function()
  local B = {}
  B.resolve = function(arg)
    if not arg or arg == "" or arg == "%" then
      return 0
    end
    if arg == "#" then
      return vim.fn.bufnr "#"
    end
    local n = tonumber(arg)
    if n then
      return n
    end
    local byname = vim.fn.bufnr(arg)
    if byname ~= -1 then
      return byname
    end
    return 0
  end
  return B
end)()

U.fs = (function()
  local F = {}

  local DIR_MODE = 0x1ED -- 493 / 0755

  ---Ensure a directory exists, creating parents as needed (best effort).
  ---@param dir string Absolute or relative directory path.
  ---@return boolean ok Directory exists or was created.
  function F.ensure_dir(dir)
    assert(type(dir) == "string" and dir ~= "", "dir must be a non-empty string")

    local stat = uv.fs_stat(dir)
    if stat and stat.type == "directory" then
      return true
    end

    local parent = fs.dirname(dir)
    if parent and parent ~= "" and parent ~= "." and parent ~= dir then
      if not F.ensure_dir(parent) then
        return false
      end
    end

    local ok, err = uv.fs_mkdir(dir, DIR_MODE)
    if ok then
      return true
    end
    if err and err:match "EEXIST" then
      return true
    end
    return false
  end

  ---Create a zero-byte file with O_EXCL semantics.
  ---@param path string Absolute or relative file path.
  ---@return boolean ok File was created exclusively.
  function F.atomic_create(path)
    assert(type(path) == "string" and path ~= "", "path must be a non-empty string")

    local fd = uv.fs_open(path, "wx", 420)
    if not fd then
      return false
    end
    uv.fs_close(fd)
    return true
  end

  ---Update both atime and mtime to the provided UNIX timestamp (seconds).
  ---@param path string Absolute or relative file path.
  ---@param ts number UNIX timestamp in seconds.
  ---@return boolean ok Times were updated.
  function F.utime(path, ts)
    assert(type(path) == "string" and path ~= "", "path must be a non-empty string")
    assert(type(ts) == "number", "ts must be a number")

    return uv.fs_utime(path, ts, ts) and true or false
  end

  ---Best-effort unlink of the provided path.
  ---@param path string Absolute or relative file path.
  ---@return boolean ok Removal succeeded or path absent.
  function F.unlink(path)
    assert(type(path) == "string" and path ~= "", "path must be a non-empty string")

    local ok, err = uv.fs_unlink(path)
    if ok then
      return true
    end
    if err and err:match "ENOENT" then
      return true
    end
    return false
  end

  ---Resolve a path to its absolute canonical form (best effort).
  ---@param path string Absolute or relative path.
  ---@return string resolved Canonical absolute path or normalized fallback.
  function F.realpath(path)
    assert(type(path) == "string" and path ~= "", "path must be a non-empty string")

    local resolved = uv.fs_realpath(path)
    if resolved then
      return resolved
    end

    local normalized = fs.normalize(path)
    if fs.isabs(normalized) then
      return normalized
    end
    return fs.joinpath(uv.cwd(), normalized)
  end

  return F
end)()

U.overcmd = (function()
  local O = {}
  local ACTIVE = {} -- [canon] = { commands={}, abbrevs={}, using_ca=bool }

  local function supports_ca_mode()
    local v = vim.version and vim.version()
    -- Neovim >= 0.10
    if v and (v.major > 0 or v.minor >= 10) and vim.keymap and vim.keymap.set then
      return true
    end
    return false
  end

  local function prefixes(token, min_len)
    min_len = min_len or 1
    local start_i = math.max(min_len, 1)
    if start_i > #token then
      return {}
    end
    return fun
      .iter(fun.range(start_i, #token))
      :map(function(i)
        return token:sub(1, i)
      end)
      :totable()
  end

  function O.teardown(canon)
    local rec = ACTIVE[canon]
    if not rec then
      return
    end
    fun.iter(rec.commands or {}):for_each(function(name)
      pcall(vim.api.nvim_del_user_command, name)
    end)
    if rec.using_ca then
      fun.iter(rec.abbrevs or {}):for_each(function(lhs)
        pcall(vim.keymap.del, "ca", lhs)
      end)
    else
      fun.iter(rec.abbrevs or {}):for_each(function(lhs)
        pcall(vim.cmd, "cunabbrev " .. lhs)
      end)
    end
    ACTIVE[canon] = nil
  end

  ---@class OverrideOpts
  ---@brief [[
  ---Override one or more Ex commands by installing smart command‑line abbreviations
  ---that expand selected prefixes to a canonical user command implemented in Lua.
  ---Works on Neovim ≥ 0.10 (cmdline keymaps) and older Vimscript-style `:cabbrev`.
  ---
  ---Example:
  ---  O.override {
  ---    from = { "bdelete", "bd" },
  ---    canon = "Bdelete",
  ---    handler = function(o)
  ---      -- o has fields like .args, .bang, .range, .fargs (see :h nvim_create_user_command())
  ---      require("mini.bufremove").delete(tonumber(o.args) or 0, o.bang)
  ---    end,
  ---    usercmd = { bang = true, nargs = "?", complete = "buffer", desc = "Delete buffer" },
  ---    min_prefix_len = 2,
  ---    also_aliases = { "bdel" },
  ---    install_late = false,
  ---  }
  ---]]
  ---@field from string|string[]  @ One or more source command tokens to override (e.g. "bd" or {"bdelete","bd"}).
  ---@field canon string          @ Canonical **User** command name to install (must start with uppercase; see :h nvim_create_user_command()).
  ---@field handler fun(o:table)  @ Lua callback invoked by the canonical command. Called with a single opts table from `nvim_create_user_command()` (fields: name, bang, args, fargs, range, count, mods, etc.).
  ---@field usercmd? table        @ Options forwarded to `nvim_create_user_command()`; common keys: `bang:boolean`, `nargs:string`, `complete:string|fun`, `desc:string`, `range`, `count`, etc.
  ---@field min_prefix_len? integer  @ Minimum prefix length to generate abbreviations for each `from` token (default: 2). For example, from="bdelete" with min_prefix_len=2 generates `bd`, `bde`, …, `bdelete`.
  ---@field also_aliases? string[]   @ Additional literal tokens to treat like `from` (merged before prefix expansion).
  ---@field install_late? boolean    @ If true, installation is scheduled via `vim.schedule()` (default: false).
  ---@field enter_fallback? any      @ Deprecated/ignored placeholder to avoid breaking older configs.

  --- Override Ex commands with a custom handler.
  ---@param opts OverrideOpts
  ---@return fun() undo  @Call to remove the override (delegates to O.teardown).
  function O.override(opts)
    assert(type(opts) == "table", "opts must be a table")
    assert(opts.from ~= nil, "from is required")

    if type(opts.from) == "string" then
    elseif type(opts.from) == "table" then
      fun.iter(opts.from):for_each(function(v)
        assert(type(v) == "string", "each from must be a string")
      end)
    else
      assert(false, "from must be a string or table of strings")
    end

    assert(type(opts.canon) == "string", "canon must be a string")

    assert(type(opts.handler) == "function", "handler must be a function")

    -- Validate optional fields if present
    if opts.usercmd ~= nil then
      assert(type(opts.usercmd) == "table", "usercmd must be a table")
    end

    if opts.min_prefix_len ~= nil then
      assert(type(opts.min_prefix_len) == "number", "min_prefix_len must be a number")
      assert(opts.min_prefix_len == math.floor(opts.min_prefix_len), "min_prefix_len must be an integer")
    end

    if opts.also_aliases ~= nil then
      assert(type(opts.also_aliases) == "table", "also_aliases must be a table")
      fun.iter(opts.also_aliases):for_each(function(v)
        assert(type(v) == "string", "each also_aliases must be a string")
      end)
    end

    if opts.install_late ~= nil then
      assert(type(opts.install_late) == "boolean", "install_late must be a boolean")
    end

    if ACTIVE[opts.canon] then
      O.teardown(opts.canon)
    end

    local tokens = type(opts.from) == "string" and { opts.from } or vim.deepcopy(opts.from)
    fun.iter(opts.also_aliases or {}):for_each(function(a)
      table.insert(tokens, a)
    end)
    local min_len = opts.min_prefix_len or 2
    local install_late = opts.install_late == true

    vim.api.nvim_create_user_command(opts.canon, opts.handler, opts.usercmd or {})
    local rec = { commands = { opts.canon }, abbrevs = {}, using_ca = supports_ca_mode() }

    local lhses, seen = {}, {}
    fun.iter(tokens):for_each(function(t)
      fun.iter(prefixes(t, min_len)):for_each(function(p)
        if not seen[p] then
          lhses[#lhses + 1] = p
          seen[p] = true
        end
      end)
    end)

    local function install()
      if rec.using_ca then
        -- Neovim ≥ 0.10: Lua cmdline abbreviation keymaps ("ca")
        fun.iter(lhses):for_each(function(lhs)
          pcall(vim.keymap.del, "ca", lhs) -- clear if present
          local expr = string.format(
            "(getcmdtype() == ':' && getcmdline() =~# '^\\s*%s\\(\\s\\|!\\|$\\)') ? '%s' : '%s'",
            lhs,
            opts.canon,
            lhs
          )
          vim.keymap.set("ca", lhs, expr, { expr = true, silent = true })
          table.insert(rec.abbrevs, lhs)
        end)
      else
        fun.iter(lhses):for_each(function(lhs)
          pcall(vim.cmd, "cunabbrev " .. lhs)
          local cmd = string.format(
            "cabbrev <expr> %s (getcmdtype()==':' && getcmdline() =~# '^\\s*%s\\(\\s\\|!\\|$\\)') ? '%s' : '%s'",
            lhs,
            lhs,
            opts.canon,
            lhs
          )
          vim.cmd(cmd)
          table.insert(rec.abbrevs, lhs)
        end)
      end
    end

    if install_late then
      vim.schedule(install)
    else
      install()
    end

    ACTIVE[opts.canon] = rec
    return function()
      O.teardown(opts.canon)
    end
  end

  O.ACTIVE = ACTIVE
  return O
end)()

function U.fzf_lua_utils(fzf_instance)
  local FL = {}

  FL.live_ripgrep = function(opts)
    opts = opts or {}

    opts.prompt = opts.prompt or "rg>"
    opts.file_icons = true
    opts.color_icons = true
    opts.actions = fzf_instance.defaults.actions.files
    opts.previewer = nil

    if opts.cwd then
      opts.cwd = opts.cwd
    end

    opts.fzf_opts = vim.tbl_extend("force", opts.fzf_opts or {}, {
      ["--delimiter"] = ":",
      ["--nth"] = "4..", -- keep the match text as the shown part (optional)
      ["--preview-window"] = "right:60%:border-left:wrap:+{2}", -- jump preview to line {2}
      ["--preview"] = [[bat --style=changes --theme=murphy --color=always --highlight-line {2} {1}]],
    })

    opts.fn_transform = nil

    local function build_search_dirs_arg()
      local dirs = opts.search_dirs

      if not dirs or (type(dirs) == "table" and #dirs == 0) then
        return ""
      end

      if type(dirs) == "string" then
        dirs = { dirs }
      end

      local joined = fun.iter(dirs):map(vim.fn.shellescape):reduce(function(acc, dir)
        return acc .. " " .. dir
      end, "")

      return " " .. joined
    end

    return fzf_instance.fzf_live(function(args)
      local q = args[1] or ""
      -- NOTE: flags → `--` → PATTERN → [PATH...]
      return "rg --column --line-number --no-heading --color=always --smart-case --max-columns=4096 -- "
        .. vim.fn.shellescape(q)
        .. build_search_dirs_arg()
    end, opts)
  end

  FL.pick_dirs_then_live_ripgrep = function(opts)
    opts = opts or {}

    local cwd = U.fs.realpath(opts.cwd or uv.cwd())
    local root = opts.list_root or "."
    local depth = opts.tree_depth or 2
    local root_abs = U.fs.realpath(root)

    -- prefer a path relative to `cwd` when it’s inside `cwd`
    local function prefer_rel_to_cwd(abs)
      abs = U.fs.realpath(abs)
      -- modern API
      if fs.relpath then
        local rel = fs.relpath(abs, cwd)
        if rel and rel ~= "" then
          return (rel:gsub("^%./", ""):gsub("/+$", ""))
        end
      end
      -- fallback: strip prefix if inside cwd
      if abs:sub(1, #cwd + 1) == (cwd .. "/") then
        return abs:sub(#cwd + 2):gsub("/+$", "")
      end
      return abs
    end

    -- dirs to exclude from the picker (fd side)
    local excludes = opts.excludes or { ".git", "node_modules", ".cache", "dist", "build", ".venv", ".next", "target" }

    -- fd command (directories only), paths relative to `root`
    local exclude_args = fun
      .iter(excludes)
      :map(function(e)
        return ("-E %s"):format(e)
      end)
      :totable()

    local fd_cmd = table.concat({
      "fd",
      "-t d",
      "-H", -- include dot dirs (drop if undesired)
      "--strip-cwd-prefix",
      "--base-directory",
      vim.fn.shellescape(root_abs),
      table.concat(exclude_args, " "),
      ".",
    }, " ")

    -- lstr preview: use ROOT because fd output is relative to ROOT
    local lstr_opts = opts.lstr_opts or { "-a", "-g", "--icons", ("-L %d"):format(depth) }
    local preview = ([[bash -lc '
set -e
PATH_TO="%s/%s"
exec lstr %s -- "$PATH_TO"
']]):format(root_abs, "{}", table.concat(lstr_opts, " "))

    fzf_instance.fzf_exec(fd_cmd, {
      cwd = cwd, -- run the picker from cwd
      prompt = "dirs> ",
      file_icons = true,
      color_icons = true,
      fzf_opts = {
        ["--multi"] = "",
        ["--header"] = ":: <CR> to grep :: <Tab> multi-select",
        ["--preview-window"] = "right,60%,border-left,wrap",
        ["--preview"] = preview,
      },
      actions = {
        ["default"] = function(selected_dirs)
          if not selected_dirs or #selected_dirs == 0 then
            return
          end

          local search_dirs = fun
            .iter(selected_dirs)
            :map(function(line)
              local abs = U.fs.realpath(root_abs .. "/" .. line)
              return prefer_rel_to_cwd(abs)
            end)
            :totable()

          FL.live_ripgrep(vim.tbl_extend("force", opts, {
            prompt = "rg " .. table.concat(search_dirs, ", ") .. ">",
            search_dirs = search_dirs,
            cwd = cwd,
          }))
        end,
      },
    })
  end

  return FL
end

-- NOTE: This solution is far from perfect and the conversion between the Mason names and LSP names
-- is lossy.
function U.mason_lspconfig(mason_lspconfig_instance)
  local ML = {}

  ---Return lspconfig name(s) for given Mason package name(s).
  ---If `packages` is a string -> returns a single string or nil.
  ---If `packages` is a list/set -> returns a list of strings.
  ---@param packages string|string[]|table<string, boolean>
  ---@return string|string[]|nil
  function ML.server_to_lsp(packages)
    local maps = mason_lspconfig_instance.get_mappings().package_to_lspconfig

    -- single package: return single RHS (or nil)
    if type(packages) == "string" then
      return maps[packages]
    end

    -- multi: return a list of RHS values
    if vim.islist(packages) then
      return fun
        .iter(packages)
        :map(function(pkg)
          return maps[pkg]
        end)
        :filter(function(lsp)
          return lsp ~= nil
        end)
        :totable()
    end

    return fun
      .iter(pairs(packages))
      :filter(function(pkg, enabled)
        return enabled and type(pkg) == "string"
      end)
      :map(function(pkg)
        return maps[pkg]
      end)
      :filter(function(lsp)
        return lsp ~= nil
      end)
      :totable()
  end

  ---Inverse: return Mason package name(s) for given lspconfig server name(s).
  ---If `servers` is a string -> returns a single string or nil.
  ---If `servers` is a list/set -> returns a list of strings.
  ---@param servers string|string[]|table<string, boolean>
  ---@return string|string[]|nil
  function ML.lsp_to_server(servers)
    local maps = mason_lspconfig_instance.get_mappings().lspconfig_to_package

    if type(servers) == "string" then
      return maps[servers]
    end

    if vim.islist(servers) then
      return fun
        .iter(servers)
        :map(function(lsp)
          return maps[lsp]
        end)
        :filter(function(pkg)
          return pkg ~= nil
        end)
        :totable()
    end

    return fun
      .iter(pairs(servers))
      :filter(function(lsp, enabled)
        return enabled and type(lsp) == "string"
      end)
      :map(function(lsp)
        return maps[lsp]
      end)
      :filter(function(pkg)
        return pkg ~= nil
      end)
      :totable()
  end

  return ML
end

return U
