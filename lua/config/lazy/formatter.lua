return {
	"mhartington/formatter.nvim",
	config = function()
		local formatter = require("formatter")
		local default_formatters = require("formatter.defaults")
		local prettierd = default_formatters.prettierd
		local prettier = default_formatters.prettier
		local stylua = default_formatters.stylua

		formatter.setup({
			filetype = {
				javascript = {
					prettierd,
				},
				javascriptreact = {
					prettierd,
				},
				typescript = {
					prettierd,
				},
				typescriptreact = {
					prettierd,
				},
				svelte = {
					prettierd,
				},
				lua = {
					stylua,
				},
			},
		})
	end,
}
