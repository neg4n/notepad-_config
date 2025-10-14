return {
	"mhartington/formatter.nvim",
	config = function()
		local formatter = require("formatter")
		local default_formatters = require("formatter.defaults")
		local prettierd = default_formatters.prettierd
		local clangformat = default_formatters.clangformat
		local stylua = default_formatters.stylua

		-- Ensure Mason bin is on PATH so biome/prettierd resolve
		local function ensure_mason_bin_on_path()
			local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
			local current = vim.env.PATH or ""
			if not current:find(vim.pesc(mason_bin), 1, true) then
				vim.env.PATH = mason_bin .. ":" .. current
			end
		end

		-- Dynamic formatter: prefer Biome when biome config exists and binary is available,
		-- otherwise fall back to Prettierd.
		local function biome_or_prettierd()
			ensure_mason_bin_on_path()
			local fname = vim.api.nvim_buf_get_name(0)
			if fname == "" then
				fname = vim.fn.expand("%:p")
			end
			local dir = (fname ~= "" and vim.fs.dirname(fname)) or vim.loop.cwd()
			local found = vim.fs.find({ "biome.json", "biome.jsonc" }, { upward = true, path = dir })
			if #found > 0 and vim.fn.executable("biome") == 1 then
				return {
					exe = "biome",
					args = { "format", "--stdin-file-path", fname },
					stdin = true,
				}
			end
			return prettierd()
		end

		formatter.setup({
			filetype = {
				cpp = { clangformat },
				lua = { stylua },
				javascript = { biome_or_prettierd },
				javascriptreact = { biome_or_prettierd },
				typescript = { biome_or_prettierd },
				typescriptreact = { biome_or_prettierd },
				vue = { biome_or_prettierd },
				svelte = { biome_or_prettierd },
				astro = { biome_or_prettierd },
			},
		})
	end,
}
