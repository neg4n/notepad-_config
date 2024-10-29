return {
	"mhartington/formatter.nvim",
	config = function()
		local formatter = require("formatter")
		local default_formatters = require("formatter.defaults")
		local prettierd = default_formatters.prettierd
    local clangformat = default_formatters.clangformat
		local prettier = default_formatters.prettier
		local stylua = default_formatters.stylua

		formatter.setup({
			filetype = {
        cpp = {
          clangformat,
        },
				javascript = {
					prettierd,
				},
				javascriptreact = {
					prettierd,
				},
				typescript = {
					prettierd,
				},
        astro = {
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
