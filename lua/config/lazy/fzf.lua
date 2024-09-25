return {
	"ibhagwan/fzf-lua",
	dependencies = {
		{ "junegunn/fzf", build = "./install --bin" },
		"BurntSushi/ripgrep",
		"sharkdp/fd",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("fzf-lua").setup({})
		require("which-key").add({
			{
				"<leader>ff",
				function()
					require("fzf-lua").files()
				end,
				desc = "Find files",
			},
			{
				"<leader>fb",
				function()
					require("fzf-lua").buffers()
				end,
				desc = "Navigate through open buffers",
			},
			{
				"<leader>/",
				function()
					require("fzf-lua").live_grep()
				end,
				desc = "Live grep",
			},
			{
				"<leader>g",
				function()
					require("fzf-lua").git_files()
				end,
				desc = "Git files",
			},
			{
				"<leader>vh",
				function()
					require("fzf-lua").help_tags()
				end,
				desc = "Help tags",
			},
		})
	end,
}
