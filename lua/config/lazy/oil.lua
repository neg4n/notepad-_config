return {
	"stevearc/oil.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local oil = require("oil")
		oil.setup({ default_file_explorer = true })

		vim.keymap.set("n", "-", "<cmd>Oil --float<CR>", { desc = "Open file explorer" })
	end,
}
