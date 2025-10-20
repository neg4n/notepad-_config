local U = {}

---@param t table
---@return table
local function shallow_clone(t)
  if type(t) ~= "table" then return t end
  local out = {}
  for k, v in pairs(t) do out[k] = v end
  return out
end

---@param keys string|string[]
---@return string[]
local function as_list(keys)
  if type(keys) == "string" then return { keys } end
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
    if o.clone == nil then o.clone = true end
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
      return vim.fn.bufnr("#")
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

-- overcmd: override built-ins via guarded command-line abbreviations
-- - Creates an uppercase canonical user command (e.g. :Bdelete).
-- - Rewrites lowercase built-ins/prefixes (bd, bde, bdel, ...) to it.
-- - Uses Lua "ca" keymaps on Neovim ≥ 0.10; falls back to :cabbrev otherwise.
U.overcmd = (function()
  local O = {}
  local ACTIVE = {}  -- [canon] = { commands={}, abbrevs={}, using_ca=bool }

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
      if not seen[p] then out[#out+1] = p; seen[p] = true end
    end
    return out
  end

  local function del_user_cmd(name) pcall(vim.api.nvim_del_user_command, name) end
  local function unset_abbrev(lhs) pcall(vim.cmd, "cunabbrev " .. lhs) end
  local function del_cmdline_map(mode, lhs) pcall(vim.keymap.del, mode, lhs) end

  function O.teardown(canon)
    local rec = ACTIVE[canon]
    if not rec then return end
    for _, name in ipairs(rec.commands or {}) do del_user_cmd(name) end
    if rec.using_ca then
      for _, lhs in ipairs(rec.abbrevs or {}) do del_cmdline_map("ca", lhs) end
    else
      for _, lhs in ipairs(rec.abbrevs or {}) do unset_abbrev(lhs) end
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
    vim.validate({
      opts    = { opts, "table" },
      from    = { opts.from, { "string", "table" } },
      canon   = { opts.canon, "string" },
      handler = { opts.handler, "function" },
    })

    if ACTIVE[opts.canon] then O.teardown(opts.canon) end

    local tokens = type(opts.from) == "string" and { opts.from } or vim.deepcopy(opts.from)
    for _, a in ipairs(opts.also_aliases or {}) do table.insert(tokens, a) end
    local min_len      = opts.min_prefix_len or 2
    local install_late = opts.install_late == true

    vim.api.nvim_create_user_command(opts.canon, opts.handler, opts.usercmd or {})
    local rec = { commands = { opts.canon }, abbrevs = {}, using_ca = supports_ca_mode() }

    local lhses, seen = {}, {}
    for _, t in ipairs(tokens) do
      for _, p in ipairs(prefixes(t, min_len)) do
        if not seen[p] then lhses[#lhses+1] = p; seen[p] = true end
      end
    end

    local function install()
      if rec.using_ca then
        -- Neovim ≥ 0.10: Lua cmdline abbreviation keymaps ("ca")
        for _, lhs in ipairs(lhses) do
          del_cmdline_map("ca", lhs)  -- clear if present
          -- Match: start (optional ws), the exact prefix, then space/! or EOL.
          -- NOTE: use \( ... \) (capturing) to avoid \%( ... ) mishaps.
          local expr = string.format(
            "(getcmdtype() == ':' && getcmdline() =~# '^\\s*%s\\(\\s\\|!\\|$\\)') ? '%s' : '%s'",
            lhs, opts.canon, lhs
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
            lhs, lhs, opts.canon, lhs
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
    return function() O.teardown(opts.canon) end
  end

  function O.status() return ACTIVE end
  return O
end)()

return U
