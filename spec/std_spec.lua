local MiniTest = require("mini.test")
local std = require("config.std")

local expect = MiniTest.expect

local expect_reference_equal = MiniTest.new_expectation("reference equality", function(left, right)
	return rawequal(left, right)
end, function(left, right)
	return string.format("Expected %s and %s to reference same object", tostring(left), tostring(right))
end)

local T = MiniTest.new_set()

T["list"] = MiniTest.new_set()

T["list"]["splits comma-separated strings"] = function()
	local result = std.list("javascript,typescript , vue")
	expect.equality(result, { "javascript", "typescript", "vue" })
end

T["list"]["copies array-like tables defensively"] = function()
	local source = { "a", "b" }
	local result = std.list(source)
	expect.equality(result, { "a", "b" })
	source[1] = "changed"
	expect.equality(result, { "a", "b" })
end

T["list"]["derives keys from totable providers"] = function()
	local iterator = {
		totable = function()
			return { "x", "y" }
		end,
	}
	expect.equality(std.list(iterator), { "x", "y" })
end

T["list"]["collects dictionary keys"] = function()
	local keys = std.list({ foo = true, bar = true })
	table.sort(keys)
	expect.equality(keys, { "bar", "foo" })
end

T["list"]["errors on unsupported key specification"] = function()
	expect.error(function()
		std.list(25)
	end, "config.std: unsupported key specification of type 'number'")
end

T["assign_many"] = MiniTest.new_set()

T["assign_many"]["clones table values per key"] = function()
	local target = std.assign_many(nil, { "a", "b" }, { count = 0 })
	expect.equality(target, { a = { count = 0 }, b = { count = 0 } })
	expect.equality(rawequal(target.a, target.b), false)
end

T["assign_many"]["mutates table by default"] = function()
	local base = { original = true }
	std.assign_many(base, "x, y", 1)
	expect.equality(base, { original = true, x = 1, y = 1 })
end

T["assign_many"]["returns copy when mutate flag is false"] = function()
	local base = { existing = true }
	local result = std.assign_many(base, { "foo" }, 42, { mutate = false })
	expect.equality(result, { existing = true, foo = 42 })
	expect.equality(base, { existing = true })
end

T["assign_many"]["supports resolver customization"] = function()
	local history = {}
	local result = std.assign_many({}, { "k1", "k2" }, { base = true }, {
		resolve = function(key, index, dest, value)
			history[#history + 1] = { key = key, index = index, snapshot = vim.deepcopy(dest) }
			return { key = key, ref = value.base }
		end,
	})

	expect.equality(result, {
		k1 = { key = "k1", ref = true },
		k2 = { key = "k2", ref = true },
	})

	expect.equality(history[1], { key = "k1", index = 1, snapshot = {} })
	expect.equality(history[2], { key = "k2", index = 2, snapshot = { k1 = { key = "k1", ref = true } } })
end

T["assign_many"]["reuses reference when clone_tables disabled"] = function()
	local shared = { x = 1 }
	local result = std.assign_many({}, { "one", "two" }, shared, { clone_tables = false })
	expect_reference_equal(result.one, shared)
	expect_reference_equal(result.two, shared)
end

T["spread"] = MiniTest.new_set()

T["spread"]["merges tables left-to-right"] = function()
	local merged = std.spread({ a = 1, b = 2 }, { b = 3, c = 4 }, { d = 5 })
	expect.equality(merged, { a = 1, b = 3, c = 4, d = 5 })
end

T["spread"]["skips non-table arguments"] = function()
	local merged = std.spread({ a = 1 }, "not a table", nil)
	expect.equality(merged, { a = 1 })
end

T["ensure_table"] = MiniTest.new_set()

T["ensure_table"]["returns unchanged table"] = function()
	local tbl = {}
	expect_reference_equal(std.ensure_table(tbl), tbl)
end

T["ensure_table"]["creates blank table for nil"] = function()
	expect.equality(std.ensure_table(nil), {})
end

T["ensure_table"]["errors on invalid type"] = function()
	expect.error(function()
		std.ensure_table("nope")
	end, "config.std.ensure_table: expected table or nil, received string")
end

T["map"] = MiniTest.new_set()

T["map"]["copies seed and supports chaining"] = function()
	local seed = { existing = true }
	local builder = std.map(seed)
	local result = builder:assign("a", 1):spread({ b = 2 })()

	expect.equality(result, { existing = true, a = 1, b = 2 })
	expect.equality(rawequal(seed, result), false)
end

T["map"]["callable builder returns table"] = function()
	local map = std.map():assign("x", 1)
	expect.equality(map(), { x = 1 })
end

return T
