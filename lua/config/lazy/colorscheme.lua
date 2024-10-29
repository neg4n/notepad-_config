function ColorMyPencils(color)
	color = color or "rose-pine"
	vim.cmd.colorscheme(color)
end

return {
  {"bettervim/yugen.nvim",
  init = function ()

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
  end, config = function ()
   require("yugen").setup();

			require("nvim-web-devicons").setup({
				{
					color_icons = false,
					override = {
						["default_icon"] = {
							color = require("lackluster").color.gray4,
							name = "Default",
						},
					},
				},
			})
  end},
	{
		"slugbyte/lackluster.nvim",
		dependencies = { "nvim-web-devicons" },
		config = function()
			require("lackluster").setup({
				tweak_ui = {
					disable_undercurl = true,
					enable_end_of_buffer = false,
				},
			})
		end,
	},
	{
		"aliqyan-21/darkvoid.nvim",
		-- config = function()
		-- require("darkvoid").setup({
		--		glow = true,
		--})
		--end,
	},
	{
		"rose-pine/neovim",
		name = "rose-pine",
		config = function()
			require("rose-pine").setup({
				variant = "moon",
				styles = {
					bold = true,
					italic = true,
					transparency = true,
				},
				highlight_groups = {
					TelescopeBorder = { fg = "highlight_high", bg = "none" },
					TelescopeNormal = { bg = "none" },
					TelescopePromptNormal = { bg = "base" },
					TelescopeResultsNormal = { fg = "subtle", bg = "none" },
					TelescopeSelection = { fg = "text", bg = "base" },
					TelescopeSelectionCaret = { fg = "rose", bg = "rose" },
				},
			})
			-- vim.cmd("colorscheme rose-pine")
			-- ColorMyPencils("rose-pine")
		end,
	},

	{
		"aktersnurra/no-clown-fiesta.nvim",
		name = "no-clown-fiesta",
		config = function()
			require("no-clown-fiesta").setup({
				transparent = true,
				styles = {
					comments = {},
					keywords = {},
					functions = {},
					variables = {},
					type = { bold = true },
					lsp = { underline = true },
				},
			})
		end,
	},
}
