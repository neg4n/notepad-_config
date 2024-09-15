return {
	"folke/zen-mode.nvim",
	config = function()
		vim.keymap.set("n", "<leader>zz", function()
			require("zen-mode").setup({
				window = {
					width = 80,
					options = {
						number = false,
						relativenumber = false,
						foldcolumn = "0",
					},
				},
			})
			require("zen-mode").toggle()
		end)
	end,
}
