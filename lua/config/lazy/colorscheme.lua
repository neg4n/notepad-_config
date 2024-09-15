function ColorMyPencils(color)
	color = color or "rose-pine"
	vim.cmd.colorscheme(color)

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

return {
	{
		"slugbyte/lackluster.nvim",
		lazy = false,
		priority = 1000,
		init = function()
			-- vim.cmd.colorscheme("lackluster")
			ColorMyPencils("lackluster-hack")
			vim.cmd.colorscheme("lackluster-hack")
			-- vim.cmd.colorscheme("lackluster-mint")
		end,
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
