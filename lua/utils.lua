local U = {}

---@param t table
---@return table
local function shallow_clone(t)
  if type(t) ~= "table" then
    return t
  end
  local out = {}
  for k, v in pairs(t) do
    out[k] = v
  end
  return out
end

---@param keys string|string[]
---@return string[]
local function as_list(keys)
  if type(keys) == "string" then
    return { keys }
  end
  assert(type(keys) == "table", "utils.tbl: keys must be a string or table")
  return keys
end

--- Chainable table wrapper.
--- Methods (all chainable unless noted):
---   :map(keys, value, opts?)         -> assign same `value` (function or any value) to many keys
---   :map_func(keys, fn, opts?)       -> alias of :map(keys, fn, opts)
---   :map_tbl(keys, tbl, opts?)       -> alias of :map(keys, tbl, opts) with default clone=true
---   :set(key, value, opts?)          -> single-key version of :map
---   :result()                        -> returns the underlying mutated table (non-chain)
---
--- opts:
---   - skip_existing:boolean? (default false)  do not overwrite if key already set
---   - clone:boolean?         (default false for :map, true for :map_tbl)
---                             when assigning tables, shallow-clone per key to avoid shared refs
---@param source table
function U.tbl(source)
  assert(type(source) == "table", "utils.tbl: source must be a table")
  local W = { _src = source }

  --- core impl
  ---@param keys string|string[]
  ---@param value any
  ---@param opts? { skip_existing?: boolean, clone?: boolean }
  function W:map(keys, value, opts)
    local o = opts or {}
    local list = as_list(keys)
    for _, k in ipairs(list) do
      if not (o.skip_existing and self._src[k] ~= nil) then
        if o.clone and type(value) == "table" then
          self._src[k] = shallow_clone(value)
        else
          self._src[k] = value
        end
      end
    end
    return self
  end

  --- isomorphic alias (function case)
  ---@param keys string|string[]
  ---@param fn   function
  ---@param opts? { skip_existing?: boolean, clone?: boolean }
  function W:map_func(keys, fn, opts)
    assert(type(fn) == "function", "utils.tbl.map_func: fn must be a function")
    return self:map(keys, fn, opts)
  end

  --- isomorphic alias (table/value case) with clone defaulting to true
  ---@param keys string|string[]
  ---@param tbl  table|any
  ---@param opts? { skip_existing?: boolean, clone?: boolean }
  function W:map_tbl(keys, tbl, opts)
    local o = opts or {}
    if o.clone == nil then
      o.clone = true
    end
    return self:map(keys, tbl, o)
  end

  --- single-key sugar
  function W:set(key, value, opts)
    return self:map({ key }, value, opts)
  end

  --- finalize
  function W:result()
    return self._src
  end

  return W
end

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

  local uv = vim.uv or vim.loop

  ---Ensure directory exists (recursive).
  ---@param dir string
  ---@return boolean ok
  function F.ensure_dir(dir)
    local ok = pcall(vim.fn.mkdir, dir, "p")
    return ok and true or false
  end

  ---Create a file atomically with O_EXCL (zero bytes).
  ---@param path string
  ---@return boolean ok
  function F.atomic_create(path)
    local fd = uv.fs_open(path, "wx", 420)
    if not fd then
      return false
    end
    uv.fs_close(fd)
    return true
  end

  ---Update atime/mtime to a given unix time (seconds).
  ---@param path string
  ---@param ts integer
  ---@return boolean ok
  function F.utime(path, ts)
    return uv.fs_utime(path, ts, ts) and true or false
  end

  ---Best-effort unlink.
  ---@param path string
  function F.unlink(path)
    pcall(uv.fs_unlink, path)
  end

  return F
end)()

U.scheduling = (function()
  local S = {}

  local uv = vim.uv or vim.loop

  local LOCK_DIR = (function()
    local p = vim.fs.joinpath(vim.fn.stdpath "data", "locks")
    U.fs.ensure_dir(p)
    return p
  end)()

  --Clears all locks from the directory they live
  S.clear_all_locks = function()
    vim.notify(LOCK_DIR)
    U.fs.unlink(LOCK_DIR)
  end

  local function sanitize(name)
    return (tostring(name):gsub("[^%w_.-]", "-"))
  end
  local function lock_path(name)
    return vim.fs.joinpath(LOCK_DIR, sanitize(name) .. ".lock")
  end
  local function lease_name(name, exp)
    return sanitize(name) .. ".lease." .. tostring(exp)
  end
  local function lease_prefix(name)
    return sanitize(name) .. ".lease."
  end

  ---Return true if TTL has expired or lock missing.
  ---@param name string
  ---@param ttl integer
  ---@return boolean due
  function S.due(name, ttl)
    local p = lock_path(name)
    local st = uv.fs_stat(p)
    if not st or not st.mtime then
      return true
    end
    local sec = type(st.mtime) == "table" and st.mtime.sec or st.mtime
    return (os.time() - (sec or 0)) >= ttl
  end

  ---Touch lock mtime (create if missing).
  ---@param name string
  ---@return boolean ok
  function S.touch(name)
    local p = lock_path(name)
    if not uv.fs_stat(p) then
      if not U.fs.atomic_create(p) then
        return false
      end
    end
    return U.fs.utime(p, os.time())
  end

  local function clean_stale_leases(name)
    local pref = lease_prefix(name)
    for entry, t in vim.fs.dir(LOCK_DIR) do
      if t == "file" and vim.startswith(entry, pref) then
        local ts = tonumber(entry:sub(#pref + 1)) or 0
        if ts <= os.time() then
          U.fs.unlink(vim.fs.joinpath(LOCK_DIR, entry))
        end
      end
    end
  end

  local function acquire_lease(name, lease_timeout)
    clean_stale_leases(name)
    local exp = os.time() + lease_timeout
    local lp = vim.fs.joinpath(LOCK_DIR, lease_name(name, exp))
    return U.fs.atomic_create(lp), lp
  end

  local function release_lease(path)
    U.fs.unlink(path)
  end

  ---@class TTLOnceOpts
  ---@field when? boolean|fun():boolean        # Gate; default true.
  ---@field autotouch? boolean                 # Auto-touch on success; default true.
  ---@field lease_timeout? integer             # Seconds; default 300.
  ---@field wait_for_lease? boolean|integer    # false|true|seconds; default false.
  ---@field notify? boolean                    # Show notifications; default true.

  ---@alias TTLOnceReason
  ---| '"ok"'
  ---| '"failed"'
  ---| '"pending"'
  ---| '"busy"'
  ---| '"error"'
  ---| '"fresh"'
  ---| '"gate-false"'

  ---@alias TTLOnceFnSync fun():boolean
  ---@alias TTLOnceFnAsync fun(done: fun(success:boolean))
  ---@alias TTLOnceTask TTLOnceFnAsync|TTLOnceFnSync

  ---Run at most once per TTL across Neovim instances.
  ---Sync: returns true/false.  Async: call the provided done(true|false).
  ---@param name string
  ---@param ttl integer
  ---@param fn TTLOnceTask
  ---@param opts? TTLOnceOpts
  ---@return boolean ran, TTLOnceReason reason
  ---@overload fun(name: string, ttl: integer, fn: TTLOnceFnSync,  opts?: TTLOnceOpts): boolean, TTLOnceReason
  ---@overload fun(name: string, ttl: integer, fn: TTLOnceFnAsync, opts?: TTLOnceOpts): boolean, TTLOnceReason
  function S.once(name, ttl, fn, opts)
    opts = opts or {}
    local when = opts.when
    local autotouch = (opts.autotouch ~= false)
    local lease_timeout = tonumber(opts.lease_timeout or 300) or 300
    local notify = (opts.notify ~= false)
    local wait_for_lease = (opts.wait_for_lease ~= nil)

    if when ~= nil then
      if type(when) == "function" then
        local ok, res = pcall(when)
        if not ok or not res then
          return false, "gate-false"
        end
      elseif not when then
        return false, "gate-false"
      end
    end

    if not S.due(name, ttl) then
      return false, "fresh"
    end

    local lease_path
    local started = os.time()
    local function try()
      local ok, lp = acquire_lease(name, lease_timeout)
      if ok then
        lease_path = lp
        return true
      end
      if not wait_for_lease then
        return false
      end
      local timeout = (wait_for_lease == true) and lease_timeout or (tonumber(wait_for_lease) or 0)
      while (os.time() - started) < timeout do
        vim.wait(100, function()
          clean_stale_leases(name)
          local ok2, lp2 = acquire_lease(name, lease_timeout)
          if ok2 then
            lease_path = lp2
            return true
          end
          return false
        end, 10, false)
        if lease_path then
          return true
        end
      end
      return false
    end
    if not try() then
      return false, "busy"
    end

    local function log(msg, lvl)
      if notify then
        vim.schedule(function()
          vim.notify("[ttl:" .. name .. "] " .. msg, lvl or vim.log.levels.INFO)
        end)
      end
    end

    local done_called = false
    local function done(success)
      if done_called then
        return
      end
      done_called = true
      if success and autotouch then
        S.touch(name)
      end
      if lease_path then
        release_lease(lease_path)
      end
    end

    local ok, ret_or_err = pcall(fn, done)
    if not ok then
      if lease_path then
        release_lease(lease_path)
      end
      log("task crashed: " .. tostring(ret_or_err), vim.log.levels.WARN)
      return false, "error"
    end

    if type(ret_or_err) == "boolean" then
      if ret_or_err and autotouch then
        S.touch(name)
      end
      if lease_path then
        release_lease(lease_path)
      end
      return true, ret_or_err and "ok" or "failed"
    else
      return true, "pending"
    end
  end

  return S
end)()

-- overcmd: override built-ins via guarded command-line abbreviations
-- - Creates an uppercase canonical user command (e.g. :Bdelete).
-- - Rewrites lowercase built-ins/prefixes (bd, bde, bdel, ...) to it.
-- - Uses Lua "ca" keymaps on Neovim ≥ 0.10; falls back to :cabbrev otherwise.
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
    local out, seen = {}, {}
    for i = math.max(min_len, 1), #token do
      local p = token:sub(1, i)
      if not seen[p] then
        out[#out + 1] = p
        seen[p] = true
      end
    end
    return out
  end

  local function del_user_cmd(name)
    pcall(vim.api.nvim_del_user_command, name)
  end
  local function unset_abbrev(lhs)
    pcall(vim.cmd, "cunabbrev " .. lhs)
  end
  local function del_cmdline_map(mode, lhs)
    pcall(vim.keymap.del, mode, lhs)
  end

  function O.teardown(canon)
    local rec = ACTIVE[canon]
    if not rec then
      return
    end
    for _, name in ipairs(rec.commands or {}) do
      del_user_cmd(name)
    end
    if rec.using_ca then
      for _, lhs in ipairs(rec.abbrevs or {}) do
        del_cmdline_map("ca", lhs)
      end
    else
      for _, lhs in ipairs(rec.abbrevs or {}) do
        unset_abbrev(lhs)
      end
    end
    ACTIVE[canon] = nil
  end

  --- Override Ex commands with a custom handler.
  -- opts = {
  --   from = "bdelete" | {"bdelete","bd"},
  --   canon = "Bdelete",
  --   handler = function(o) ... end,
  --   usercmd = { bang=true, nargs="?", complete="buffer", desc="..." },
  --   min_prefix_len = 2,
  --   also_aliases = {...},
  --   install_late = false,
  --   enter_fallback = (deprecated, ignored),
  -- }
  function O.override(opts)
    vim.validate {
      opts = { opts, "table" },
      from = { opts.from, { "string", "table" } },
      canon = { opts.canon, "string" },
      handler = { opts.handler, "function" },
    }

    if ACTIVE[opts.canon] then
      O.teardown(opts.canon)
    end

    local tokens = type(opts.from) == "string" and { opts.from } or vim.deepcopy(opts.from)
    for _, a in ipairs(opts.also_aliases or {}) do
      table.insert(tokens, a)
    end
    local min_len = opts.min_prefix_len or 2
    local install_late = opts.install_late == true

    vim.api.nvim_create_user_command(opts.canon, opts.handler, opts.usercmd or {})
    local rec = { commands = { opts.canon }, abbrevs = {}, using_ca = supports_ca_mode() }

    local lhses, seen = {}, {}
    for _, t in ipairs(tokens) do
      for _, p in ipairs(prefixes(t, min_len)) do
        if not seen[p] then
          lhses[#lhses + 1] = p
          seen[p] = true
        end
      end
    end

    local function install()
      if rec.using_ca then
        -- Neovim ≥ 0.10: Lua cmdline abbreviation keymaps ("ca")
        for _, lhs in ipairs(lhses) do
          del_cmdline_map("ca", lhs) -- clear if present
          -- Match: start (optional ws), the exact prefix, then space/! or EOL.
          -- NOTE: use \( ... \) (capturing) to avoid \%( ... ) mishaps.
          local expr = string.format(
            "(getcmdtype() == ':' && getcmdline() =~# '^\\s*%s\\(\\s\\|!\\|$\\)') ? '%s' : '%s'",
            lhs,
            opts.canon,
            lhs
          )
          vim.keymap.set("ca", lhs, expr, { expr = true, silent = true })
          table.insert(rec.abbrevs, lhs)
        end
      else
        -- Older: use :cabbrev <expr>
        for _, lhs in ipairs(lhses) do
          unset_abbrev(lhs)
          local cmd = string.format(
            "cabbrev <expr> %s (getcmdtype()==':' && getcmdline() =~# '^\\s*%s\\(\\s\\|!\\|$\\)') ? '%s' : '%s'",
            lhs,
            lhs,
            opts.canon,
            lhs
          )
          vim.cmd(cmd)
          table.insert(rec.abbrevs, lhs)
        end
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

  function O.status()
    return ACTIVE
  end
  return O
end)()

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
    local out = {}
    if vim.islist(packages) then
      for _, pkg in ipairs(packages) do
        local lsp = maps[pkg]
        if lsp then table.insert(out, lsp) end
      end
    else
      for pkg, enabled in pairs(packages) do
        if enabled and type(pkg) == "string" then
          local lsp = maps[pkg]
          if lsp then table.insert(out, lsp) end
        end
      end
    end
    return out
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

    local out = {}
    if vim.islist(servers) then
      for _, lsp in ipairs(servers) do
        local pkg = maps[lsp]
        if pkg then table.insert(out, pkg) end
      end
    else
      for lsp, enabled in pairs(servers) do
        if enabled and type(lsp) == "string" then
          local pkg = maps[lsp]
          if pkg then table.insert(out, pkg) end
        end
      end
    end
    return out
  end

  return ML
end


return U
