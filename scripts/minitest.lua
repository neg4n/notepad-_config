local uv = vim.loop

vim.loader.enable(false)
vim.opt.shadafile = "NONE"

local root = uv.cwd()

local function ensure_rtp(path)
	if not vim.tbl_contains(vim.opt.runtimepath:get(), path) then
		vim.opt.runtimepath:append(path)
	end
end

local function append_package_path(path)
	local new_paths = {
		path .. "/lua/?.lua",
		path .. "/lua/?/init.lua",
	}
	package.path = table.concat(vim.tbl_flatten({ new_paths, package.path }), ";")
end

local function ensure_dir(path)
	local stat = uv.fs_stat(path)
	if not stat then
		vim.fn.mkdir(path, "p")
	end
end

local cache_dir = vim.fn.stdpath("cache")
ensure_dir(cache_dir .. "/luac")

local data_path = vim.fn.stdpath("data")
local mini_test_path = data_path .. "/lazy/mini.test"

if not uv.fs_stat(mini_test_path) then
	error(("mini.test not found at %s. Ensure it is installed via your plugin manager."):format(mini_test_path))
end

ensure_rtp(root)
ensure_rtp(mini_test_path)
append_package_path(root)
append_package_path(mini_test_path)

local MiniTest = require("mini.test")

MiniTest.setup({
	collect = {
		find_files = function()
			return vim.fn.globpath("spec", "**/*_spec.lua", true, true)
		end,
	},
})

MiniTest.run({
	execute = {
		reporter = MiniTest.gen_reporter.stdout(),
	},
})
