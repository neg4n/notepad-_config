-- lua/config/std.lua
-- Utilities shared across the Neovim config.

local std = {}

local deepcopy = vim.deepcopy
local tbl_islist = vim.islist

---@class config.std.MapBuilder
---@field private _state table
local MapBuilder = {}
MapBuilder.__index = MapBuilder

local function copy_list(list)
	return table.move(list, 1, #list, 1, {})
end

local function normalize_keys(keys)
	if keys == nil then
		return {}
	end

	local kind = type(keys)

	if kind == "string" then
		local result = {}
		for key in keys:gmatch("[^,%s]+") do
			if #key > 0 then
				result[#result + 1] = key
			end
		end
		return result
	end

	if kind == "table" then
		if type(keys.totable) == "function" then
			local ok, list = pcall(keys.totable, keys)
			if ok then
				return list
			end
		end

		if tbl_islist(keys) then
			return copy_list(keys)
		end

		local result = {}
		for key in pairs(keys) do
			result[#result + 1] = key
		end

		return result
	end

	error(("config.std: unsupported key specification of type '%s'"):format(kind))
end

---Create a defensive list copy out of a supported key specification.
---@param keys string|string[]|table|vim.iter.Iterator
---@return string[]
function std.list(keys)
	return normalize_keys(keys)
end

---Assign a single value (or generated value) to multiple keys in a table.
---Keys can be provided as a comma separated string, a list-like table,
---a dictionary (keys are inferred), or a `vim.iter` iterator.
---@param target table|nil Destination table (mutated unless opts.mutate == false). Created when nil.
---@param keys string|string[]|table|vim.iter.Iterator Keys to receive the value.
---@param value any Value to assign. Leave as table to duplicate per key, or use opts.resolve.
---@param opts? { mutate?: boolean, clone_tables?: boolean, resolve?: fun(key:string, index:integer, existing:table, value:any):any }
---@return table destination The table with assignments applied.
function std.assign_many(target, keys, value, opts)
	opts = opts or {}
	local dest = target

	if dest == nil then
		dest = {}
	elseif opts.mutate == false then
		dest = deepcopy(dest)
	end

	local resolved_keys = normalize_keys(keys)
	if #resolved_keys == 0 then
		return dest
	end

	local clone_tables = opts.clone_tables ~= false
	local resolver = opts.resolve

	for index, key in ipairs(resolved_keys) do
		local assigned = value

		if resolver then
			assigned = resolver(key, index, dest, value)
		end

		if clone_tables and type(assigned) == "table" then
			dest[key] = deepcopy(assigned)
		else
			dest[key] = assigned
		end
	end

	return dest
end

---Spread multiple tables into a fresh table, similar to JS object spread.
---@param ... table
---@return table
function std.spread(...)
	local result = {}
	for i = 1, select("#", ...) do
		local segment = select(i, ...)
		if type(segment) == "table" then
			for key, value in pairs(segment) do
				result[key] = value
			end
		end
	end
	return result
end

---Ensure the provided value is a table (empty table by default).
---@generic T
---@param value T|nil
---@return T|table
function std.ensure_table(value)
	if type(value) == "table" then
		return value
	end

	if value == nil then
		return {}
	end

	error(("config.std.ensure_table: expected table or nil, received %s"):format(type(value)))
end

---Create a map builder that allows fluent multi-key assignments.
---@param seed? table|nil Optional starting table (copied defensively).
---@return config.std.MapBuilder
function std.map(seed)
	local state = seed and deepcopy(seed) or {}
	return setmetatable({ _state = state }, MapBuilder)
end

---Assign keys inside the builder.
---@param keys string|string[]|table|vim.iter.Iterator
---@param value any
---@param opts? { clone_tables?: boolean, resolve?: fun(key:string, index:integer, existing:table, value:any):any }
---@return config.std.MapBuilder
function MapBuilder:assign(keys, value, opts)
	std.assign_many(self._state, keys, value, opts)
	return self
end

---Merge in additional tables using std.spread semantics.
---@param ... table
---@return config.std.MapBuilder
function MapBuilder:spread(...)
	self._state = std.spread(self._state, ...)
	return self
end

---Expose the builder's underlying table (no copy).
---@return table
function MapBuilder:result()
	return self._state
end

MapBuilder.__call = MapBuilder.result

return std
