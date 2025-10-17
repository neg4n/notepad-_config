return {
	{
		"bettervim/yugen.nvim",
		init = function()
			vim.cmd.colorscheme("yugen")
			vim.api.nvim_set_hl(0, "FzfLuaBorder", { fg = "#444444" })
			vim.api.nvim_set_hl(0, "FzfLuaTitle", { fg = "#7788AA", bold = true })
			vim.api.nvim_set_hl(0, "FzfLuaBackdrop", { bg = "#080808" })
			vim.api.nvim_set_hl(0, "FzfLuaCursor", { fg = "#000000", bg = "#FFBE89" })
			vim.api.nvim_set_hl(0, "FzfLuaCursorLine", { bg = "#303030" })
			vim.api.nvim_set_hl(0, "FzfLuaFzfMarker", { fg = "#000000", bg = "#FFBE89" })
			vim.api.nvim_set_hl(0, "FzfLuaFzfCursorLine", { link = "FzfLuaCursorLine" })
			vim.api.nvim_set_hl(0, "FzfLuaFzfBorder", { link = "FzfLuaBorder" })
			vim.api.nvim_set_hl(0, "FzfLuaFzfPointer", { link = "FzfLuaTitle" })

			vim.api.nvim_set_hl(0, "RenderMarkdownCode", { link = "FzfLuaTitle" })
			vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { link = "FzfLuaTitle" })
		end,
		config = function()
			require("yugen").setup()

			require("nvim-web-devicons").setup({
				{
	 			color_icons = false,
				},
			})
      vim.cmd.colorscheme("yugen")
		end,
	}
}
