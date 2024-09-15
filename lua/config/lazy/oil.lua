return {
	"stevearc/oil.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("oil").setup({ default_file_explorer = true })
		require("which-key").add({
			{ "-", "<CMD>Oil --float<CR>", desc = "Open file explorer", icon = "" },
		})
	end,
}
