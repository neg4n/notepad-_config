return {
	"ibhagwan/fzf-lua",
	dependencies = {
		{ "junegunn/fzf", build = "./install --bin" },
		"BurntSushi/ripgrep",
		"sharkdp/fd",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("fzf-lua").setup({
			"max-perf",
			fzf_colors = true,
			previewers = {
				bat = {
					cmd = "bat",
					args = "--color=always --style=changes",
				},
			},
			winopts = {
				height = 0.55,
				width = 0.60,
				row = 1,
				col = 0,
				backdrop = 50,
        border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
				preview = {

        border = "border-top",

					vertical = "down:45%",
					horizontal = "right:60%",
					winopts = {
            preview = "none",
						cursorline = false,
						number = false,
					},
				},
			},
		})
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
